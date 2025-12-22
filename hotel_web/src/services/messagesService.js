import { 
  collection, 
  doc, 
  addDoc, 
  setDoc,
  getDoc,
  query, 
  where, 
  orderBy, 
  limit, 
  onSnapshot, 
  updateDoc,
  getDocs,
  Timestamp,
  serverTimestamp,
  FieldValue
} from 'firebase/firestore'
import { getFirebaseFirestore } from '../config/firebase'
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage'
import { getFirebaseStorage } from '../config/firebase'

const db = getFirebaseFirestore()
const storage = getFirebaseStorage()

if (!db) {
  console.error('❌ Firestore is not initialized')
}

/**
 * Generate conversation ID between two users (same as mobile)
 * Format: userId1_userId2 (sorted alphabetically)
 */
export const getConversationId = (userId1, userId2) => {
  const sorted = [userId1, userId2].sort()
  return `${sorted[0]}_${sorted[1]}`
}

/**
 * Get or create conversation between two users (same format as mobile)
 */
export const getOrCreateConversation = async (userId1, userId2, otherUserName, otherUserEmail, otherUserRole) => {
  if (!db) {
    throw new Error('Firestore is not initialized')
  }

  const conversationId = getConversationId(userId1, userId2)
  const conversationRef = doc(db, 'conversations', conversationId)

  try {
    // Check if conversation exists
    const conversationDoc = await getDoc(conversationRef)

    if (!conversationDoc.exists()) {
      // Create new conversation (same format as mobile)
      await setDoc(conversationRef, {
        participants: [userId1, userId2],
        participantNames: {
          [userId1]: 'Hotel Manager',
          [userId2]: otherUserName
        },
        participantEmails: {
          [userId1]: '',
          [userId2]: otherUserEmail
        },
        participantRoles: {
          [userId1]: 'hotel_manager',
          [userId2]: otherUserRole
        },
        lastActivity: serverTimestamp(),
        isActive: true,
        readStatus: {
          [userId1]: true,
          [userId2]: false
        },
        unreadCount: {
          [userId1]: 0,
          [userId2]: 0
        }
      })
    }

    return conversationId
  } catch (error) {
    console.error('Error getting/creating conversation:', error)
    throw error
  }
}

/**
 * Send a text message (same format as mobile)
 */
export const sendTextMessage = async (conversationId, senderId, senderRole, messageText, senderName = '', senderEmail = '', receiverId = '', receiverName = '', receiverEmail = '', receiverRole = '') => {
  if (!db) {
    throw new Error('Firestore is not initialized')
  }

  try {
    const messagesRef = collection(db, 'conversations', conversationId, 'messages')
    
    // Generate message ID
    const messageId = doc(messagesRef).id
    
    const messageData = {
      senderId: senderId,
      senderName: senderName || 'Hotel Manager',
      senderEmail: senderEmail,
      senderRole: senderRole, // 'hotel_manager', 'user', 'admin'
      receiverId: receiverId,
      receiverName: receiverName,
      receiverEmail: receiverEmail,
      receiverRole: receiverRole,
      content: messageText,
      type: 'text',
      timestamp: serverTimestamp(),
      isRead: false
    }

    await setDoc(doc(messagesRef, messageId), messageData)

    // Update conversation (same format as mobile)
    const conversationRef = doc(db, 'conversations', conversationId)
    const conversationDoc = await getDoc(conversationRef)
    const convData = conversationDoc.data() || {}
    const participants = convData.participants || []
    const otherParticipantId = participants.find(p => p !== senderId) || receiverId
    
    await updateDoc(conversationRef, {
      lastMessage: messageData,
      lastActivity: serverTimestamp(),
      [`unreadCount.${otherParticipantId}`]: FieldValue.increment(1),
      [`readStatus.${senderId}`]: true,
      [`readStatus.${otherParticipantId}`]: false
    })

    return messageId
  } catch (error) {
    console.error('Error sending text message:', error)
    throw error
  }
}

/**
 * Send an image message (same format as mobile)
 */
export const sendImageMessage = async (conversationId, senderId, senderRole, imageFile, senderName = '', senderEmail = '', receiverId = '', receiverName = '', receiverEmail = '', receiverRole = '') => {
  if (!db || !storage) {
    throw new Error('Firebase is not initialized')
  }

  try {
    // Upload image to Firebase Storage
    const imageRef = ref(storage, `messages/${conversationId}/${Date.now()}_${imageFile.name}`)
    await uploadBytes(imageRef, imageFile)
    const imageUrl = await getDownloadURL(imageRef)

    // Save message to Firestore
    const messagesRef = collection(db, 'conversations', conversationId, 'messages')
    const messageId = doc(messagesRef).id
    
    const messageData = {
      senderId: senderId,
      senderName: senderName || 'Hotel Manager',
      senderEmail: senderEmail,
      senderRole: senderRole,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverEmail: receiverEmail,
      receiverRole: receiverRole,
      content: imageUrl,
      type: 'image',
      imageUrl: imageUrl,
      timestamp: serverTimestamp(),
      isRead: false
    }

    await setDoc(doc(messagesRef, messageId), messageData)

    // Update conversation (same format as mobile)
    const conversationRef = doc(db, 'conversations', conversationId)
    const conversationDoc = await getDoc(conversationRef)
    const convData = conversationDoc.data() || {}
    const participants = convData.participants || []
    const otherParticipantId = participants.find(p => p !== senderId) || receiverId
    
    await updateDoc(conversationRef, {
      lastMessage: {
        ...messageData,
        content: '[Hình ảnh]'
      },
      lastActivity: serverTimestamp(),
      [`unreadCount.${otherParticipantId}`]: FieldValue.increment(1),
      [`readStatus.${senderId}`]: true,
      [`readStatus.${otherParticipantId}`]: false
    })

    return { messageId, imageUrl }
  } catch (error) {
    console.error('Error sending image message:', error)
    throw error
  }
}

/**
 * Get messages for a conversation (same format as mobile)
 */
export const getMessages = async (conversationId, limitCount = 50) => {
  if (!db) {
    throw new Error('Firestore is not initialized')
  }

  try {
    const messagesRef = collection(db, 'conversations', conversationId, 'messages')
    const q = query(messagesRef, orderBy('timestamp', 'desc'), limit(limitCount))
    
    const snapshot = await getDocs(q)
    const messages = snapshot.docs.map(doc => {
      const data = doc.data()
      return {
        id: doc.id,
        senderId: data.senderId || data.sender_id,
        senderName: data.senderName || data.sender_name,
        senderEmail: data.senderEmail || data.sender_email,
        senderRole: data.senderRole || data.sender_role,
        receiverId: data.receiverId || data.receiver_id,
        receiverName: data.receiverName || data.receiver_name,
        receiverEmail: data.receiverEmail || data.receiver_email,
        receiverRole: data.receiverRole || data.receiver_role,
        content: data.content,
        type: data.type || data.message_type,
        imageUrl: data.imageUrl || data.image_url,
        timestamp: data.timestamp?.toDate() || data.created_at?.toDate() || new Date(),
        isRead: data.isRead || data.is_read || false
      }
    })

    return messages.reverse() // Reverse to show oldest first
  } catch (error) {
    console.error('Error getting messages:', error)
    throw error
  }
}

/**
 * Listen to messages in real-time (same format as mobile)
 */
export const subscribeToMessages = (conversationId, callback) => {
  if (!db) {
    console.error('Firestore is not initialized')
    return () => {}
  }

  try {
    const messagesRef = collection(db, 'conversations', conversationId, 'messages')
    const q = query(messagesRef, orderBy('timestamp', 'asc'))

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const messages = snapshot.docs.map(doc => {
        const data = doc.data()
        return {
          id: doc.id,
          senderId: data.senderId || data.sender_id,
          senderName: data.senderName || data.sender_name,
          senderEmail: data.senderEmail || data.sender_email,
          senderRole: data.senderRole || data.sender_role,
          receiverId: data.receiverId || data.receiver_id,
          receiverName: data.receiverName || data.receiver_name,
          receiverEmail: data.receiverEmail || data.receiver_email,
          receiverRole: data.receiverRole || data.receiver_role,
          content: data.content,
          type: data.type || data.message_type,
          imageUrl: data.imageUrl || data.image_url,
          timestamp: data.timestamp?.toDate() || data.created_at?.toDate() || new Date(),
          isRead: data.isRead || data.is_read || false
        }
      })
      callback(messages)
    }, (error) => {
      console.error('Error listening to messages:', error)
      // Try without orderBy if index is missing
      try {
        const fallbackQ = query(messagesRef)
        const fallbackUnsubscribe = onSnapshot(fallbackQ, (snapshot) => {
          const messages = snapshot.docs.map(doc => {
            const data = doc.data()
            return {
              id: doc.id,
              senderId: data.senderId || data.sender_id,
              senderName: data.senderName || data.sender_name,
              senderEmail: data.senderEmail || data.sender_email,
              senderRole: data.senderRole || data.sender_role,
              receiverId: data.receiverId || data.receiver_id,
              receiverName: data.receiverName || data.receiver_name,
              receiverEmail: data.receiverEmail || data.receiver_email,
              receiverRole: data.receiverRole || data.receiver_role,
              content: data.content,
              type: data.type || data.message_type,
              imageUrl: data.imageUrl || data.image_url,
              timestamp: data.timestamp?.toDate() || data.created_at?.toDate() || new Date(),
              isRead: data.isRead || data.is_read || false
            }
          })
          // Sort by timestamp on client
          messages.sort((a, b) => a.timestamp - b.timestamp)
          callback(messages)
        })
        return fallbackUnsubscribe
      } catch (fallbackError) {
        console.error('Error with fallback query:', fallbackError)
      }
    })

    return unsubscribe
  } catch (error) {
    console.error('Error subscribing to messages:', error)
    return () => {}
  }
}

/**
 * Mark messages as read (same format as mobile)
 */
export const markMessagesAsRead = async (conversationId, readerId) => {
  if (!db) {
    throw new Error('Firestore is not initialized')
  }

  try {
    // Update unread count in conversation (same format as mobile)
    const conversationRef = doc(db, 'conversations', conversationId)
    await updateDoc(conversationRef, {
      [`unreadCount.${readerId}`]: 0,
      [`readStatus.${readerId}`]: true,
      lastActivity: serverTimestamp()
    })

    // Update message isRead statuses
    const messagesRef = collection(db, 'conversations', conversationId, 'messages')
    const q = query(
      messagesRef,
      where('receiverId', '==', readerId),
      where('isRead', '==', false)
    )
    
    const snapshot = await getDocs(q)
    const updatePromises = snapshot.docs.map(doc => {
      return updateDoc(doc.ref, {
        isRead: true
      })
    })

    await Promise.all(updatePromises)
  } catch (error) {
    console.error('Error marking messages as read:', error)
    throw error
  }
}

/**
 * Get unread count for a conversation (same format as mobile)
 */
export const getUnreadCount = async (conversationId, userId) => {
  if (!db) {
    return 0
  }

  try {
    const conversationRef = doc(db, 'conversations', conversationId)
    const conversationDoc = await getDoc(conversationRef)
    
    if (!conversationDoc.exists()) {
      return 0
    }

    const data = conversationDoc.data()
    return data.unreadCount?.[userId] || data.unread_count?.[userId] || 0
  } catch (error) {
    console.error('Error getting unread count:', error)
    return 0
  }
}

/**
 * Listen to conversations for a user (same format as mobile)
 */
export const subscribeToConversations = (userId, callback) => {
  if (!db) {
    console.error('Firestore is not initialized')
    return () => {}
  }

  try {
    const conversationsRef = collection(db, 'conversations')
    const q = query(
      conversationsRef,
      where('participants', 'array-contains', userId)
    )

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const conversations = snapshot.docs.map(doc => {
        const data = doc.data()
        return {
          id: doc.id,
          ...data,
          lastActivity: data.lastActivity?.toDate() || data.last_activity?.toDate() || new Date(),
          last_message_time: data.lastMessage?.timestamp?.toDate() || data.lastActivity?.toDate() || null
        }
      })
      // Sort by lastActivity on client (in case orderBy index is missing)
      conversations.sort((a, b) => b.lastActivity - a.lastActivity)
      callback(conversations)
    }, (error) => {
      console.error('Error listening to conversations:', error)
    })

    return unsubscribe
  } catch (error) {
    console.error('Error subscribing to conversations:', error)
    return () => {}
  }
}
