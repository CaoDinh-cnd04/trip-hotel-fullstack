// Mock API service for payment processing
export const paymentService = {
  // Generate QR code for MoMo payment
  generateMoMoQR: async (amount, orderId, description) => {
    // Simulate API call
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        if (amount <= 0) {
          reject(new Error('Invalid amount'))
          return
        }

        // Create real MoMo payment URL (using demo phone number)
        const momoPaymentUrl = `https://nhantien.momo.vn/0369119368?amount=${amount}&note=${encodeURIComponent(description)}`
        
        resolve({
          success: true,
          data: {
            qrCode: `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(momoPaymentUrl)}&format=png&margin=10`,
            paymentUrl: momoPaymentUrl,
            orderId: orderId,
            amount: amount,
            description: description,
            expiryTime: new Date(Date.now() + 15 * 60 * 1000).toISOString(), // 15 minutes
            deepLink: `momo://transfer?phone=0369119368&amount=${amount}&note=${encodeURIComponent(description)}`
          }
        })
      }, 1000)
    })
  },

  // Generate QR code for ZaloPay payment
  generateZaloPayQR: async (amount, orderId, description) => {
    // Simulate API call
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        if (amount <= 0) {
          reject(new Error('Invalid amount'))
          return
        }

        // Create ZaloPay QR content (simplified for demo)
        const zaloPayContent = `2|99|${orderId}|${amount}|${description}|TripHotel`
        
        resolve({
          success: true,
          data: {
            qrCode: `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(zaloPayContent)}&format=png&margin=10`,
            paymentUrl: `zalopay://qr/p/${orderId}/${amount}`,
            orderId: orderId,
            amount: amount,
            description: description,
            expiryTime: new Date(Date.now() + 15 * 60 * 1000).toISOString(), // 15 minutes
            deepLink: `zalopay://qr/p/${orderId}/${amount}`
          }
        })
      }, 1000)
    })
  },

  // Check payment status
  checkPaymentStatus: async (orderId, paymentMethod) => {
    // Simulate API call to check payment status
    return new Promise((resolve) => {
      setTimeout(() => {
        // Randomly simulate success/pending for demo
        const statuses = ['success', 'pending', 'failed']
        const randomStatus = statuses[Math.floor(Math.random() * statuses.length)]
        
        resolve({
          success: true,
          data: {
            orderId: orderId,
            status: randomStatus,
            paymentMethod: paymentMethod,
            transactionId: randomStatus === 'success' ? `TXN${Date.now()}` : null,
            paidAmount: randomStatus === 'success' ? 1000000 : 0,
            paidAt: randomStatus === 'success' ? new Date().toISOString() : null
          }
        })
      }, 1500)
    })
  },

  // Verify payment (manual confirmation)
  verifyPayment: async (orderId, paymentMethod) => {
    // Simulate payment verification
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve({
          success: true,
          data: {
            orderId: orderId,
            status: 'success',
            paymentMethod: paymentMethod,
            transactionId: `TXN${Date.now()}`,
            verifiedAt: new Date().toISOString()
          }
        })
      }, 1000)
    })
  }
}

// Hotel booking service
export const bookingService = {
  // Create booking
  createBooking: async (bookingData) => {
    return new Promise((resolve) => {
      setTimeout(() => {
        const bookingId = `TH${Date.now()}`
        resolve({
          success: true,
          data: {
            ...bookingData,
            id: bookingId,
            createdAt: new Date().toISOString(),
            status: 'confirmed'
          }
        })
      }, 1000)
    })
  },

  // Get booking details
  getBooking: async (bookingId) => {
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve({
          success: true,
          data: {
            id: bookingId,
            status: 'confirmed',
            // ... other booking details
          }
        })
      }, 500)
    })
  }
}