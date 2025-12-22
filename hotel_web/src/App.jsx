import React from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from './stores/authStore'
import Layout from './components/Layout/Layout'
import ErrorBoundary from './components/common/ErrorBoundary'

// Public Pages
import HomePage from './pages/public/HomePage'
import HotelsPage from './pages/public/HotelsPage'
import HotelDetailPage from './pages/public/HotelDetailPage'
import BookingPage from './pages/public/BookingPage'
import SearchResultsPage from './pages/public/SearchResultsPage'
import PromotionsPage from './pages/public/PromotionsPage'
import ContactPage from './pages/public/ContactPage'
import HelpCenterPage from './pages/public/HelpCenterPage'
import AboutUsPage from './pages/public/AboutUsPage'

// Auth Pages
import LoginPage from './pages/auth/LoginPage'
import LoginWithPasswordPage from './pages/auth/LoginWithPasswordPage'
import OTPLoginPage from './pages/auth/OTPLoginPage'
import AuthPage from './pages/auth/AuthPage'

// User Pages
import FavoritesPage from './pages/user/FavoritesPage'
import ProfilePage from './pages/user/ProfilePage'
import BookingsPage from './pages/user/BookingsPage'
import PaymentPage from './pages/user/PaymentPage'
import NotificationsPage from './pages/user/NotificationsPage'
import MyReviewsPage from './pages/user/MyReviewsPage'
import MessagesPage from './pages/user/MessagesPage'
import AccountSecurityPage from './pages/user/AccountSecurityPage'
import TriphotelVipPage from './pages/user/TriphotelVipPage'
import SavedCardsPage from './pages/user/SavedCardsPage'

// Admin Pages
import Overview from './pages/admin/Overview'
import Hotels from './pages/admin/Hotels'
import Users from './pages/admin/Users'
import Rooms from './pages/admin/Rooms'
import Discounts from './pages/admin/Discounts'
import Bookings from './pages/admin/Bookings'
import Reviews from './pages/admin/Reviews'
import SystemReports from './pages/admin/SystemReports'
import AdminDashboard from './pages/admin/AdminDashboard'
import AdminLoginPage from './pages/admin/AdminLoginPage'
import AdminRegisterPage from './pages/admin/AdminRegisterPage'

// Manager Pages
import ManagerDashboard from './pages/manager/ManagerDashboard'
import ManagerLoginPage from './pages/manager/ManagerLoginPage'

// Protected Route Component
const ProtectedRoute = ({ children }) => {
  const isAuthenticated = () => useAuthStore.getState().isAuthenticated()
  
  return isAuthenticated() ? children : <Navigate to="/login" replace />
}

// Auth Route Component (redirect to home if already logged in)
const AuthRoute = ({ children }) => {
  const isAuthenticated = () => useAuthStore.getState().isAuthenticated()
  
  return !isAuthenticated() ? children : <Navigate to="/" replace />
}

// Admin Protected Route Component
const AdminProtectedRoute = ({ children }) => {
  const { isAdmin } = useAuthStore()
  const isAuthenticated = () => useAuthStore.getState().isAuthenticated()
  
  // Debug: Log authentication status
  React.useEffect(() => {
    console.log('AdminProtectedRoute - isAuthenticated:', isAuthenticated())
    console.log('AdminProtectedRoute - isAdmin:', isAdmin())
    console.log('AdminProtectedRoute - user:', useAuthStore.getState().user)
  }, [])
  
  if (!isAuthenticated()) {
    console.log('Not authenticated, redirecting to /admin/login')
    return <Navigate to="/admin/login" replace />
  }
  
  if (!isAdmin()) {
    console.log('Not admin, redirecting to /')
    return <Navigate to="/" replace />
  }
  
  return children
}

// Manager Protected Route Component
const ManagerProtectedRoute = ({ children }) => {
  const { isHotelManager } = useAuthStore()
  const isAuthenticated = () => useAuthStore.getState().isAuthenticated()
  
  // Debug: Log authentication status
  React.useEffect(() => {
    console.log('ManagerProtectedRoute - isAuthenticated:', isAuthenticated())
    console.log('ManagerProtectedRoute - isHotelManager:', isHotelManager())
    console.log('ManagerProtectedRoute - user:', useAuthStore.getState().user)
  }, [])
  
  if (!isAuthenticated()) {
    console.log('Not authenticated, redirecting to /manager/login')
    return <Navigate to="/manager/login" replace />
  }
  
  if (!isHotelManager()) {
    console.log('Not hotel manager, redirecting to /')
    console.log('ManagerProtectedRoute - User role:', useAuthStore.getState().user?.role)
    console.log('ManagerProtectedRoute - User chuc_vu:', useAuthStore.getState().user?.chuc_vu)
    return <Navigate to="/" replace />
  }
  
  return <ErrorBoundary>{children}</ErrorBoundary>
}

function App() {
  const { initializeAuth } = useAuthStore()
  
  // Initialize auth on app start
  React.useEffect(() => {
    initializeAuth()
  }, [initializeAuth])

  return (
    <div className="App">
      <ErrorBoundary>
        <Routes>
        {/* Public Routes */}
        <Route path="/" element={<Layout><HomePage /></Layout>} />
        <Route path="/hotels" element={<Layout><HotelsPage /></Layout>} />
        <Route path="/hotels/:id" element={<Layout><HotelDetailPage /></Layout>} />
        <Route path="/booking" element={<Layout><BookingPage /></Layout>} />
        <Route path="/search" element={<Layout><SearchResultsPage /></Layout>} />
        <Route path="/promotions" element={<Layout><PromotionsPage /></Layout>} />
        <Route path="/contact" element={<Layout><ContactPage /></Layout>} />
        <Route path="/favorites" element={<Layout><FavoritesPage /></Layout>} /> {/* Public - can view without login */}

        
        {/* Auth Routes */}
        <Route path="/login" element={
          <AuthRoute>
            <LoginPage />
          </AuthRoute>
        } />
        <Route path="/login-with-password" element={
          <AuthRoute>
            <LoginWithPasswordPage />
          </AuthRoute>
        } />
        <Route path="/login-otp" element={
          <AuthRoute>
            <OTPLoginPage />
          </AuthRoute>
        } />
        <Route path="/register" element={
          <AuthRoute>
            <AuthPage />
          </AuthRoute>
        } />
        
        {/* Admin Auth Routes */}
        <Route path="/admin/login" element={<AdminLoginPage />} />
        <Route path="/admin/register" element={<AdminRegisterPage />} />
        
        {/* Manager Auth Routes */}
        <Route path="/manager/login" element={<ManagerLoginPage />} />
        
        {/* Protected Routes */}
        <Route path="/profile" element={
          <ProtectedRoute>
            <Layout><ProfilePage /></Layout>
          </ProtectedRoute>
        } />
        <Route path="/bookings" element={
          <ProtectedRoute>
            <Layout><BookingsPage /></Layout>
          </ProtectedRoute>
        } />
        <Route path="/payment/:bookingId" element={
          <ProtectedRoute>
            <Layout><PaymentPage /></Layout>
          </ProtectedRoute>
        } />
        <Route path="/notifications" element={
          <ProtectedRoute>
            <Layout><NotificationsPage /></Layout>
          </ProtectedRoute>
        } />
        <Route path="/my-reviews" element={
          <ProtectedRoute>
            <Layout><MyReviewsPage /></Layout>
          </ProtectedRoute>
        } />
        <Route path="/messages" element={
          <ProtectedRoute>
            <Layout><MessagesPage /></Layout>
          </ProtectedRoute>
        } />
        <Route path="/account-security" element={
          <ProtectedRoute>
            <Layout><AccountSecurityPage /></Layout>
          </ProtectedRoute>
        } />
        <Route path="/vip" element={
          <ProtectedRoute>
            <Layout><TriphotelVipPage /></Layout>
          </ProtectedRoute>
        } />
        <Route path="/help" element={<Layout><HelpCenterPage /></Layout>} />
        <Route path="/about" element={<Layout><AboutUsPage /></Layout>} />
        <Route path="/saved-cards" element={
          <ProtectedRoute>
            <Layout><SavedCardsPage /></Layout>
          </ProtectedRoute>
        } />

        
        {/* Admin Routes */}
        <Route path="/admin" element={<Navigate to="/admin/overview" replace />} />
        <Route path="/admin/overview" element={
          <ProtectedRoute>
            <Overview />
          </ProtectedRoute>
        } />
        <Route path="/admin/hotels" element={
          <ProtectedRoute>
            <Hotels />
          </ProtectedRoute>
        } />
        <Route path="/admin/users" element={
          <ProtectedRoute>
            <Users />
          </ProtectedRoute>
        } />
        <Route path="/admin/rooms" element={
          <ProtectedRoute>
            <Rooms />
          </ProtectedRoute>
        } />
        <Route path="/admin/discounts" element={
          <ProtectedRoute>
            <Discounts />
          </ProtectedRoute>
        } />
        <Route path="/admin/bookings" element={
          <ProtectedRoute>
            <Bookings />
          </ProtectedRoute>
        } />
        <Route path="/admin/reviews" element={
          <ProtectedRoute>
            <Reviews />
          </ProtectedRoute>
        } />
        <Route path="/admin/reports" element={
          <ProtectedRoute>
            <SystemReports />
          </ProtectedRoute>
        } />
        
        {/* Admin Hotel Dashboard Routes */}
        <Route path="/admin-hotel" element={
          <AdminProtectedRoute>
            <AdminDashboard />
          </AdminProtectedRoute>
        } />
        <Route path="/admin-hotel/:section" element={
          <AdminProtectedRoute>
            <AdminDashboard />
          </AdminProtectedRoute>
        } />
        
        {/* Manager Routes */}
        <Route path="/manager-hotel" element={
          <ManagerProtectedRoute>
            <ErrorBoundary>
              <ManagerDashboard />
            </ErrorBoundary>
          </ManagerProtectedRoute>
        } />
        <Route path="/manager-hotel/:section" element={
          <ManagerProtectedRoute>
            <ErrorBoundary>
              <ManagerDashboard />
            </ErrorBoundary>
          </ManagerProtectedRoute>
        } />
        
        {/* Catch all route */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
      </ErrorBoundary>
    </div>
  )
}

export default App