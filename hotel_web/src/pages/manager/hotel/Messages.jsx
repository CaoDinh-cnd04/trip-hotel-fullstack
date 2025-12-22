import { useState, useEffect, useRef } from 'react'
import { motion } from 'framer-motion'
import { 
  MessageSquare, 
  Search, 
  Send, 
  Image as ImageIcon, 
  Check, 
  CheckCheck, 
  Clock,
  User,
  Calendar,
  DoorOpen,
  Loader2
} from 'lucide-react'
import toast from 'react-hot-toast'
import { useAuthStore } from '../../../stores/authStore'
import {
  getOrCreateConversation,
  sendTextMessage,
  sendImageMessage,
  subscribeToMessages,
  subscribeToConversations,
  markMessagesAsRead,
  getConversationId
} from '../../../services/messagesService'
import { collection, query, where, getDocs, getDoc, setDoc, doc, orderBy, onSnapshot, serverTimestamp } from 'firebase/firestore'
import { getFirebaseFirestore } from '../../../config/firebase'
import { isFirebaseAuthenticated, getCurrentFirebaseUser, authenticateWithFirebaseEmail } from '../../../utils/firebaseAuth'

const Messages = () => {
  const { user } = useAuthStore()
  const hotelId = user?.hotel_id || user?.data?.id
  const managerId = user?.id
  
  const [conversations, setConversations] = useState([])
  const [selectedConversation, setSelectedConversation] = useState(null)
  const [messages, setMessages] = useState([])
  const [messageText, setMessageText] = useState('')
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const [unreadCounts, setUnreadCounts] = useState({})
  
  const messagesEndRef = useRef(null)
  const fileInputRef = useRef(null)
  const unsubscribeMessagesRef = useRef(null)
  const unsubscribeConversationsRef = useRef(null)
  const db = getFirebaseFirestore()

  // Subscribe to conversations from Firestore
  useEffect(() => {
    if (!db || !managerId) {
      setLoading(false)
      return
    }

    try {
      // Get manager's Firebase UID from user_mapping or users collection
      const loadConversations = async () => {
        try {
          // First, check if user is authenticated with Firebase
          let firebaseUser = getCurrentFirebaseUser()
          let managerFirebaseUid = null
          
          // Wait a bit for Firebase Auth to initialize (in case custom token was just used)
          if (!firebaseUser) {
            console.log('ℹ️ Waiting for Firebase Auth to initialize...')
            // Wait up to 3 seconds for Firebase Auth to complete
            for (let i = 0; i < 6; i++) {
              await new Promise(resolve => setTimeout(resolve, 500))
              firebaseUser = getCurrentFirebaseUser()
              if (firebaseUser) {
                console.log('✅ Firebase Auth initialized after', (i + 1) * 500, 'ms')
                break
              }
            }
          }
          
          // If authenticated, use Firebase UID directly
          if (firebaseUser) {
            managerFirebaseUid = firebaseUser.uid
            console.log('✅ Using Firebase authenticated UID:', managerFirebaseUid)
            
            // Save mapping to user_mapping collection for future reference
            try {
              await setDoc(doc(db, 'user_mapping', managerId.toString()), {
                firebase_uid: managerFirebaseUid,
                email: user?.email?.toLowerCase() || '',
                updated_at: serverTimestamp()
              }, { merge: true })
              console.log('✅ Saved Firebase UID mapping')
            } catch (mappingError) {
              console.warn('⚠️ Failed to save Firebase UID mapping:', mappingError.message)
            }
          } else {
            console.warn('⚠️ Firebase user not authenticated. Checking user_mapping...')
            // Try to get Firebase UID from user_mapping collection
            try {
              const mappingDoc = await getDoc(doc(db, 'user_mapping', managerId.toString()))
              if (mappingDoc.exists()) {
                managerFirebaseUid = mappingDoc.data()?.firebase_uid
                console.log('✅ Found Firebase UID from user_mapping:', managerFirebaseUid)
              }
            } catch (error) {
              if (error.code === 'permission-denied' || error.message?.includes('permission')) {
                console.warn('⚠️ Permission denied accessing user_mapping. Firestore rules may need configuration.')
              } else {
                console.warn('Error getting user_mapping:', error)
              }
            }
            
            // If not found, try users collection by backend_user_id
            if (!managerFirebaseUid) {
              try {
                const usersQuery = query(
                  collection(db, 'users'),
                  where('backend_user_id', '==', managerId.toString())
                )
                const usersSnapshot = await getDocs(usersQuery)
                if (!usersSnapshot.empty) {
                  managerFirebaseUid = usersSnapshot.docs[0].id
                  console.log('✅ Found Firebase UID from users collection:', managerFirebaseUid)
                }
              } catch (error) {
                if (error.code === 'permission-denied' || error.message?.includes('permission')) {
                  console.warn('⚠️ Permission denied accessing users collection. Firestore rules may need configuration.')
                } else {
                  console.warn('Error querying users:', error)
                }
              }
            }
            
            // Last resort: use backend user ID as Firebase UID
            // Custom token creates Firebase user with UID = backend user ID
            if (!managerFirebaseUid) {
              console.warn('⚠️ Manager Firebase UID not found in Firestore.')
              console.warn('💡 Using backend user ID as Firebase UID (custom token should have created user with this UID)')
              managerFirebaseUid = managerId.toString()
              console.log('✅ Using backend user ID as Firebase UID:', managerFirebaseUid)
            }
          }
          
          console.log('✅ Final Manager Firebase UID:', managerFirebaseUid)
          
          // Also check for offline placeholder UID (in case conversations were created with it)
          const offlineUid = `offline_${managerId}`
          console.log('🔍 Also checking for offline UID:', offlineUid)
          
          // Subscribe to conversations where manager is a participant
          // Query for both current UID and offline placeholder UID
          const conversationsQuery = query(
            collection(db, 'conversations'),
            where('participants', 'array-contains', managerFirebaseUid)
          )
          
          // Also query for offline UID conversations (if different)
          let offlineQuery = null
          if (offlineUid !== managerFirebaseUid) {
            offlineQuery = query(
              collection(db, 'conversations'),
              where('participants', 'array-contains', offlineUid)
            )
          }
          
          console.log('🔍 Subscribing to conversations with UID:', managerFirebaseUid)
          if (offlineQuery) {
            console.log('🔍 Also subscribing to conversations with offline UID:', offlineUid)
          }
          
          unsubscribeConversationsRef.current = onSnapshot(conversationsQuery, (snapshot) => {
            console.log('📨 Conversations snapshot received:', {
              size: snapshot.size,
              empty: snapshot.empty,
              docs: snapshot.docs.length
            })
            
            const conversationsData = snapshot.docs.map(doc => {
              const data = doc.data()
              console.log('📋 Conversation data:', {
                id: doc.id,
                participants: data.participants,
                participantNames: data.participantNames || data.participant_names
              })
              const participants = data.participants || []
              const participantNames = data.participantNames || data.participant_names || {}
              const participantEmails = data.participantEmails || data.participant_emails || {}
              const participantRoles = data.participantRoles || data.participant_roles || {}
              const metadata = data.metadata || {}
              
              // Get other participant (customer)
              const otherParticipantId = participants.find(p => p !== managerFirebaseUid)
              const customerName = participantNames[otherParticipantId] || metadata.user_name || 'Khách hàng'
              const customerEmail = participantEmails[otherParticipantId] || metadata.user_email || ''
              
              // Get booking info from metadata
              const bookingInfo = {
                booking_id: metadata.booking_id || null,
                hotel_name: metadata.hotel_name || null,
                room_name: metadata.room_name || null,
                check_in: metadata.check_in || null,
                check_out: metadata.check_out || null
              }
              
              // Get unread count for manager
              const unreadCount = data.unreadCount?.[managerFirebaseUid] || 
                                 data.unread_count?.[managerFirebaseUid] || 0
              
              return {
                id: doc.id,
                conversationId: doc.id,
                customer_id: otherParticipantId,
                customer_name: customerName,
                customer_email: customerEmail,
                customer_avatar: null,
                last_message: data.lastMessage?.content || data.last_message || null,
                last_message_time: data.lastActivity?.toDate() || data.last_message_time?.toDate() || null,
                unread_count: unreadCount,
                latest_booking: bookingInfo.booking_id ? {
                  booking_id: bookingInfo.booking_id,
                  room_name: bookingInfo.room_name,
                  check_in: bookingInfo.check_in,
                  check_out: bookingInfo.check_out,
                  status: null,
                  booking_date: null
                } : null
              }
            })
            
            // Sort by last message time
            conversationsData.sort((a, b) => {
              const timeA = a.last_message_time ? new Date(a.last_message_time).getTime() : 0
              const timeB = b.last_message_time ? new Date(b.last_message_time).getTime() : 0
              return timeB - timeA
            })
            
            console.log('✅ Processed conversations:', conversationsData.length)
            if (conversationsData.length > 0) {
              console.log('📋 First conversation:', conversationsData[0])
            }
            
            setConversations(conversationsData)
            
            // Update unread counts
            const counts = {}
            conversationsData.forEach(conv => {
              counts[conv.id] = conv.unread_count || 0
            })
            setUnreadCounts(counts)
            setLoading(false)
            
            // If no conversations found, also check offline UID
            if (conversationsData.length === 0 && offlineQuery) {
              console.log('⚠️ No conversations found with UID:', managerFirebaseUid)
              console.log('🔍 Checking for conversations with offline UID:', offlineUid)
              onSnapshot(offlineQuery, (offlineSnapshot) => {
                console.log('📨 Offline conversations snapshot:', {
                  size: offlineSnapshot.size,
                  empty: offlineSnapshot.empty
                })
                if (!offlineSnapshot.empty) {
                  console.warn('⚠️ Found conversations with offline UID. These may need to be migrated.')
                  console.warn('💡 Consider updating conversations to use Firebase UID:', managerFirebaseUid)
                  console.warn('📋 Offline conversations:', offlineSnapshot.docs.map(d => ({
                    id: d.id,
                    participants: d.data().participants
                  })))
                } else {
                  console.info('ℹ️ No conversations found in Firestore.')
                  console.info('💡 Conversations are created when customers book rooms from the mobile app.')
                  console.info('💡 To test: Have a customer book a room from the mobile app, then conversations will appear here.')
                }
              }, (offlineError) => {
                console.warn('⚠️ Error querying offline conversations:', offlineError)
              })
            } else if (conversationsData.length === 0) {
              console.info('ℹ️ No conversations found in Firestore.')
              console.info('💡 Conversations are created when customers book rooms from the mobile app.')
              console.info('💡 To test: Have a customer book a room from the mobile app, then conversations will appear here.')
            }
          }, (error) => {
            console.error('Error listening to conversations:', error)
            if (error.code === 'permission-denied' || error.message?.includes('permission')) {
              console.error('❌ Firestore permission denied. Please configure Firestore security rules.')
              console.error('📋 Hướng dẫn: Vào Firebase Console → Firestore Database → Rules')
              console.error('📋 Hoặc chạy: firebase deploy --only firestore:rules')
              const firebaseUser = getCurrentFirebaseUser()
              if (!firebaseUser) {
                toast.error('Chưa authenticate với Firebase. Vui lòng đăng nhập lại bằng Email/Password (không dùng OTP) để sử dụng tính năng chat.', {
                  duration: 8000
                })
                console.error('❌ Chưa authenticate với Firebase. App đang dùng offline placeholder.')
                console.log('💡 Giải pháp: Đăng xuất và đăng nhập lại bằng Email/Password (không dùng OTP)')
                console.log('📖 Xem thêm: hotel_web/HUONG_DAN_FIX_FIRESTORE.md')
              } else {
                toast.error('Không có quyền truy cập Firestore. Vui lòng cấu hình Firestore rules.', {
                  duration: 5000
                })
              }
            }
            setLoading(false)
          })
        } catch (error) {
          console.error('Error loading conversations:', error)
          setLoading(false)
        }
      }
      
      loadConversations()
    } catch (error) {
      console.error('Error setting up conversations listener:', error)
      setLoading(false)
    }

    return () => {
      if (unsubscribeConversationsRef.current) {
        unsubscribeConversationsRef.current()
      }
    }
  }, [db, managerId])

  // Subscribe to messages when conversation is selected
  useEffect(() => {
    if (!selectedConversation || !db) return

    const conversationId = selectedConversation.conversationId || selectedConversation.id
    
    // Mark as read when opening conversation
    // Get manager's Firebase UID first (async function)
    const markAsRead = async () => {
      let managerFirebaseUid = null
      try {
        const mappingDoc = await getDoc(doc(db, 'user_mapping', managerId.toString()))
        if (mappingDoc.exists()) {
          managerFirebaseUid = mappingDoc.data()?.firebase_uid
        }
        if (!managerFirebaseUid) {
          const usersQuery = query(
            collection(db, 'users'),
            where('backend_user_id', '==', managerId.toString())
          )
          const usersSnapshot = await getDocs(usersQuery)
          if (!usersSnapshot.empty) {
            managerFirebaseUid = usersSnapshot.docs[0].id
          }
        }
        if (!managerFirebaseUid) {
          managerFirebaseUid = `offline_${managerId}`
        }
        if (managerFirebaseUid) {
          markMessagesAsRead(conversationId, managerFirebaseUid).catch(console.error)
        }
      } catch (error) {
        console.error('Error marking messages as read:', error)
      }
    }
    
    markAsRead()

    unsubscribeMessagesRef.current = subscribeToMessages(conversationId, (messagesData) => {
      setMessages(messagesData)
      // Scroll to bottom
      setTimeout(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
      }, 100)
    })

    return () => {
      if (unsubscribeMessagesRef.current) {
        unsubscribeMessagesRef.current()
      }
    }
  }, [selectedConversation, db, managerId])

  // Scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSelectConversation = (conversation) => {
    setSelectedConversation(conversation)
  }

  const handleSendMessage = async () => {
    if (!messageText.trim() || !selectedConversation || !db) return

    try {
      setSending(true)
      const conversationId = selectedConversation.conversationId || selectedConversation.id
      
      // Get manager's Firebase UID
      let managerFirebaseUid = null
      try {
        const mappingDoc = await getDoc(doc(db, 'user_mapping', managerId.toString()))
        if (mappingDoc.exists()) {
          managerFirebaseUid = mappingDoc.data()?.firebase_uid
        }
        if (!managerFirebaseUid) {
          // Try users collection
          const usersQuery = query(
            collection(db, 'users'),
            where('backend_user_id', '==', managerId.toString())
          )
          const usersSnapshot = await getDocs(usersQuery)
          if (!usersSnapshot.empty) {
            managerFirebaseUid = usersSnapshot.docs[0].id
          }
        }
        if (!managerFirebaseUid) {
          managerFirebaseUid = `offline_${managerId}`
        }
      } catch (error) {
        console.error('Error getting manager Firebase UID:', error)
        managerFirebaseUid = `offline_${managerId}`
      }
      
      // Get conversation data to extract receiver info
      const conversationDoc = await getDoc(doc(db, 'conversations', conversationId))
      const convData = conversationDoc.data() || {}
      const participants = convData.participants || []
      const receiverId = participants.find(p => p !== managerFirebaseUid) || selectedConversation.customer_id
      const participantNames = convData.participantNames || convData.participant_names || {}
      const participantEmails = convData.participantEmails || convData.participant_emails || {}
      const participantRoles = convData.participantRoles || convData.participant_roles || {}
      
      await sendTextMessage(
        conversationId,
        managerFirebaseUid,
        'hotel_manager',
        messageText.trim(),
        user?.ho_ten || 'Hotel Manager',
        user?.email || '',
        receiverId,
        participantNames[receiverId] || selectedConversation.customer_name,
        participantEmails[receiverId] || selectedConversation.customer_email,
        participantRoles[receiverId] || 'user'
      )

      setMessageText('')
    } catch (error) {
      console.error('Error sending message:', error)
      toast.error('Lỗi khi gửi tin nhắn')
    } finally {
      setSending(false)
    }
  }

  const handleSendImage = async (e) => {
    const file = e.target.files?.[0]
    if (!file || !selectedConversation || !db) return

    if (!file.type.startsWith('image/')) {
      toast.error('Vui lòng chọn file ảnh')
      return
    }

    if (file.size > 5 * 1024 * 1024) {
      toast.error('Kích thước ảnh không được vượt quá 5MB')
      return
    }

    try {
      setSending(true)
      const conversationId = selectedConversation.conversationId || selectedConversation.id
      
      // Get manager's Firebase UID
      let managerFirebaseUid = null
      try {
        const mappingDoc = await getDoc(doc(db, 'user_mapping', managerId.toString()))
        if (mappingDoc.exists()) {
          managerFirebaseUid = mappingDoc.data()?.firebase_uid
        }
        if (!managerFirebaseUid) {
          // Try users collection
          const usersQuery = query(
            collection(db, 'users'),
            where('backend_user_id', '==', managerId.toString())
          )
          const usersSnapshot = await getDocs(usersQuery)
          if (!usersSnapshot.empty) {
            managerFirebaseUid = usersSnapshot.docs[0].id
          }
        }
        if (!managerFirebaseUid) {
          managerFirebaseUid = `offline_${managerId}`
        }
      } catch (error) {
        console.error('Error getting manager Firebase UID:', error)
        managerFirebaseUid = `offline_${managerId}`
      }
      
      // Get conversation data to extract receiver info
      const conversationDoc = await getDoc(doc(db, 'conversations', conversationId))
      const convData = conversationDoc.data() || {}
      const participants = convData.participants || []
      const receiverId = participants.find(p => p !== managerFirebaseUid) || selectedConversation.customer_id
      const participantNames = convData.participantNames || convData.participant_names || {}
      const participantEmails = convData.participantEmails || convData.participant_emails || {}
      const participantRoles = convData.participantRoles || convData.participant_roles || {}
      
      await sendImageMessage(
        conversationId,
        managerFirebaseUid,
        'hotel_manager',
        file,
        user?.ho_ten || 'Hotel Manager',
        user?.email || '',
        receiverId,
        participantNames[receiverId] || selectedConversation.customer_name,
        participantEmails[receiverId] || selectedConversation.customer_email,
        participantRoles[receiverId] || 'user'
      )

      toast.success('Đã gửi hình ảnh')
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
    } catch (error) {
      console.error('Error sending image:', error)
      toast.error('Lỗi khi gửi hình ảnh')
    } finally {
      setSending(false)
    }
  }

  const formatTime = (date) => {
    if (!date) return ''
    const d = new Date(date)
    const now = new Date()
    const diff = now - d
    const minutes = Math.floor(diff / 60000)
    
    if (minutes < 1) return 'Vừa xong'
    if (minutes < 60) return `${minutes} phút trước`
    if (minutes < 1440) return `${Math.floor(minutes / 60)} giờ trước`
    return d.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' })
  }

  const formatMessageTime = (date) => {
    if (!date) return ''
    const d = new Date(date)
    return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
  }

  const getStatusIcon = (status) => {
    switch (status) {
      case 'read':
        return <CheckCheck className="text-blue-500" size={16} />
      case 'delivered':
        return <CheckCheck className="text-gray-400" size={16} />
      case 'sent':
        return <Check className="text-gray-400" size={16} />
      default:
        return <Clock className="text-gray-300" size={16} />
    }
  }

  // Filter conversations by search query
  const filteredConversations = conversations.filter(conv =>
    conv.customer_name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    conv.customer_email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    conv.latest_booking?.room_name?.toLowerCase().includes(searchQuery.toLowerCase())
  )

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="animate-spin h-12 w-12 text-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">Đang tải tin nhắn...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-br from-blue-600 via-blue-500 to-blue-700 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold mb-2">Tin nhắn</h1>
              <p className="text-blue-100">Giao tiếp với khách hàng của bạn</p>
            </div>
            <div className="flex items-center gap-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
                <input
                  type="text"
                  placeholder="Tìm kiếm..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10 pr-4 py-2 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-white"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 -mt-8 pb-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Conversations List */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-xl shadow-sm overflow-hidden">
              {filteredConversations.length > 0 ? (
                <div className="divide-y divide-gray-100 max-h-[calc(100vh-200px)] overflow-y-auto">
                  {filteredConversations.map((conversation) => (
                    <motion.div
                      key={conversation.id}
                      onClick={() => handleSelectConversation(conversation)}
                      className={`p-4 cursor-pointer hover:bg-gray-50 transition-colors ${
                        selectedConversation?.id === conversation.id ? 'bg-blue-50 border-l-4 border-blue-600' : ''
                      }`}
                      whileHover={{ x: 2 }}
                    >
                      <div className="flex items-start gap-3">
                        <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0 overflow-hidden">
                          {conversation.customer_avatar ? (
                            <img src={conversation.customer_avatar} alt={conversation.customer_name} className="w-full h-full object-cover" />
                          ) : (
                            <User className="text-blue-600" size={24} />
                          )}
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between mb-1">
                            <h3 className="font-semibold text-gray-900 truncate">
                              {conversation.customer_name}
                            </h3>
                            {conversation.unread_count > 0 && (
                              <span className="bg-red-500 text-white text-xs rounded-full px-2 py-0.5 min-w-[20px] text-center">
                                {conversation.unread_count}
                              </span>
                            )}
                          </div>
                          {conversation.latest_booking?.room_name && (
                            <div className="flex items-center gap-2 text-xs text-gray-500 mb-1">
                              <DoorOpen size={12} />
                              <span className="truncate">{conversation.latest_booking.room_name}</span>
                            </div>
                          )}
                          {conversation.latest_booking?.check_in && conversation.latest_booking?.check_out && (
                            <div className="flex items-center gap-2 text-xs text-gray-500 mb-1">
                              <Calendar size={12} />
                              <span>
                                {new Date(conversation.latest_booking.check_in).toLocaleDateString('vi-VN')} - {new Date(conversation.latest_booking.check_out).toLocaleDateString('vi-VN')}
                              </span>
                            </div>
                          )}
                          <p className="text-sm text-gray-500 truncate">
                            {conversation.last_message || 'Chưa có tin nhắn'}
                          </p>
                          <p className="text-xs text-gray-400 mt-1">
                            {formatTime(conversation.last_message_time)}
                          </p>
                        </div>
                      </div>
                    </motion.div>
                  ))}
                </div>
              ) : (
                <div className="p-12 text-center">
                  <MessageSquare size={64} className="mx-auto text-gray-300 mb-4" />
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">Chưa có tin nhắn</h3>
                  <p className="text-gray-500 text-sm">
                    Các tin nhắn từ khách hàng sẽ hiển thị ở đây
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Chat Area */}
          <div className="lg:col-span-2">
            {selectedConversation ? (
              <div className="bg-white rounded-xl shadow-sm flex flex-col h-[calc(100vh-200px)]">
                {/* Chat Header */}
                <div className="border-b border-gray-200 p-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center overflow-hidden">
                      {selectedConversation.customer_avatar ? (
                        <img src={selectedConversation.customer_avatar} alt={selectedConversation.customer_name} className="w-full h-full object-cover" />
                      ) : (
                        <User className="text-blue-600" size={20} />
                      )}
                    </div>
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900">
                        {selectedConversation.customer_name}
                      </h3>
                      {selectedConversation.latest_booking?.room_name && (
                        <p className="text-xs text-gray-500">
                          {selectedConversation.latest_booking.room_name} • {selectedConversation.customer_email}
                        </p>
                      )}
                    </div>
                  </div>
                </div>

                {/* Messages */}
                <div className="flex-1 overflow-y-auto p-4 space-y-4">
                  {messages.length > 0 ? (
                    messages.map((message) => (
                      <div
                        key={message.id}
                        className={`flex ${message.senderRole === 'hotel_manager' || message.senderRole === 'manager' ? 'justify-end' : 'justify-start'}`}
                      >
                        <div className={`max-w-[70%] ${message.senderRole === 'hotel_manager' || message.senderRole === 'manager' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-900'} rounded-lg p-3`}>
                          {message.type === 'image' || message.message_type === 'image' ? (
                            <div>
                              <img 
                                src={message.imageUrl || message.content} 
                                alt="Message" 
                                className="max-w-full h-auto rounded mb-2"
                                onError={(e) => {
                                  e.target.src = '/placeholder-image.png'
                                }}
                              />
                              {message.image_name && (
                                <p className="text-xs opacity-75 mt-1">{message.image_name}</p>
                              )}
                            </div>
                          ) : (
                            <p className="whitespace-pre-wrap">{message.content}</p>
                          )}
                          <div className={`flex items-center gap-1 mt-2 text-xs ${message.senderRole === 'hotel_manager' || message.senderRole === 'manager' ? 'text-blue-100' : 'text-gray-500'}`}>
                            <span>{formatMessageTime(message.timestamp || message.created_at)}</span>
                            {(message.senderRole === 'hotel_manager' || message.senderRole === 'manager') && (
                              <span className="ml-1">{getStatusIcon(message.isRead ? 'read' : message.status || 'sent')}</span>
                            )}
                          </div>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="text-center text-sm text-gray-500 py-8">
                      Chưa có tin nhắn nào. Bắt đầu cuộc trò chuyện!
                    </div>
                  )}
                  <div ref={messagesEndRef} />
                </div>

                {/* Message Input */}
                <div className="border-t border-gray-200 p-4">
                  <div className="flex items-center gap-2">
                    <input
                      type="file"
                      ref={fileInputRef}
                      accept="image/*"
                      onChange={handleSendImage}
                      className="hidden"
                    />
                    <button
                      onClick={() => fileInputRef.current?.click()}
                      disabled={sending}
                      className="p-2 text-gray-500 hover:text-blue-600 transition-colors disabled:opacity-50"
                      title="Gửi hình ảnh"
                    >
                      <ImageIcon size={20} />
                    </button>
                    <input
                      type="text"
                      placeholder="Nhập tin nhắn..."
                      value={messageText}
                      onChange={(e) => setMessageText(e.target.value)}
                      onKeyPress={(e) => {
                        if (e.key === 'Enter' && !e.shiftKey) {
                          e.preventDefault()
                          handleSendMessage()
                        }
                      }}
                      className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                      disabled={sending}
                    />
                    <button
                      onClick={handleSendMessage}
                      disabled={!messageText.trim() || sending}
                      className="bg-blue-600 text-white p-2 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {sending ? (
                        <Loader2 className="animate-spin" size={20} />
                      ) : (
                        <Send size={20} />
                      )}
                    </button>
                  </div>
                </div>
              </div>
            ) : (
              <div className="bg-white rounded-xl shadow-sm p-12 text-center h-[calc(100vh-200px)] flex items-center justify-center">
                <div>
                  <MessageSquare size={64} className="mx-auto text-gray-300 mb-4" />
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">
                    Chọn một cuộc trò chuyện
                  </h3>
                  <p className="text-gray-500 text-sm">
                    Chọn một cuộc trò chuyện từ danh sách để xem tin nhắn
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default Messages

