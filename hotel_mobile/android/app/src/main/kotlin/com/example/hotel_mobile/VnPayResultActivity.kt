package com.example.hotel_mobile

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import android.content.Intent
import android.net.Uri

/**
 * Activity để nhận callback từ VNPay SDK
 * Khi người dùng thanh toán xong và mở lại app, VNPay sẽ gọi activity này với scheme "vnpayresult"
 */
class VnPayResultActivity : AppCompatActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Xử lý intent từ VNPay
        val data: Uri? = intent?.data
        val action = intent?.action
        
        if (data != null && Intent.ACTION_VIEW == action) {
            // Lấy các tham số từ URL callback
            val responseCode = data.getQueryParameter("vnp_ResponseCode")
            val transactionNo = data.getQueryParameter("vnp_TransactionNo")
            val amount = data.getQueryParameter("vnp_Amount")
            val orderId = data.getQueryParameter("vnp_TxnRef")
            val bankCode = data.getQueryParameter("vnp_BankCode")
            val payDate = data.getQueryParameter("vnp_PayDate")
            
            // Gửi kết quả về Flutter qua Broadcast
            val resultIntent = Intent("vnpay.payment.result").apply {
                addCategory(Intent.CATEGORY_DEFAULT)
                setPackage(packageName) // Chỉ gửi trong cùng app
                putExtra("responseCode", responseCode)
                putExtra("transactionNo", transactionNo)
                putExtra("amount", amount)
                putExtra("orderId", orderId)
                putExtra("bankCode", bankCode)
                putExtra("payDate", payDate)
                putExtra("isSuccess", responseCode == "00")
            }
            sendBroadcast(resultIntent)
        }
        
        // Đóng activity này và quay về MainActivity
        finish()
    }
}

