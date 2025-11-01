package com.example.hotel_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// VNPay SDK imports - chỉ import nếu AAR tồn tại
// import com.vnpay.authentication.VNP_AuthenticationActivity
// import com.vnpay.authentication.VNP_SdkCompletedCallback

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.hotel_mobile/vnpay"
    private var paymentResultChannel: MethodChannel? = null
    private var currentPaymentCallback: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        paymentResultChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        paymentResultChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "openVnPaySdk" -> {
                    // TODO: VNPay SDK chưa được tích hợp - cần copy AAR file vào libs/
                    result.error("VNPAY_SDK_NOT_AVAILABLE", "VNPay SDK AAR file not found. Please copy merchant-1.0.25.aar to android/app/libs/", null)
                }
                "isAvailable" -> {
                    result.success(false) // VNPay SDK chưa có
                }
                "isEmulator" -> {
                    // Kiểm tra xem có phải emulator không
                    val isEmulator = checkIsEmulator()
                    result.success(isEmulator)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Đăng ký receiver để nhận kết quả từ VnPayResultActivity
        val filter = IntentFilter("vnpay.payment.result")
        LocalBroadcastManager.getInstance(this).registerReceiver(paymentResultReceiver, filter)
    }

    // TODO: Uncomment khi đã copy VNPay AAR file vào libs/
    /*
    private fun openVnPaySdk(
        url: String,
        tmnCode: String,
        scheme: String,
        isSandbox: Boolean,
        result: MethodChannel.Result
    ) {
        try {
            currentPaymentCallback = result
            
            val intent = Intent(this, VNP_AuthenticationActivity::class.java)
            intent.putExtra("url", url)
            intent.putExtra("tmn_code", tmnCode)
            intent.putExtra("scheme", scheme)
            intent.putExtra("is_sandbox", isSandbox)
            
            VNP_AuthenticationActivity.setSdkCompletedCallback(object : VNP_SdkCompletedCallback {
                override fun sdkAction(action: String) {
                    Log.d("VNPaySDK", "SDK Action: $action")
                    
                    when (action) {
                        "AppBackAction" -> {
                            currentPaymentCallback?.success(mapOf(
                                "success" to false,
                                "reason" to "user_cancelled",
                                "action" to action
                            ))
                            currentPaymentCallback = null
                        }
                        "CallMobileBankingApp" -> {
                            Log.d("VNPaySDK", "User selected Mobile Banking payment")
                        }
                        "WebBackAction" -> {
                            currentPaymentCallback?.success(mapOf(
                                "success" to false,
                                "reason" to "web_back",
                                "action" to action
                            ))
                            currentPaymentCallback = null
                        }
                        "FaildBackAction" -> {
                            currentPaymentCallback?.success(mapOf(
                                "success" to false,
                                "reason" to "payment_failed",
                                "action" to action
                            ))
                            currentPaymentCallback = null
                        }
                        "SuccessBackAction" -> {
                            Log.d("VNPaySDK", "Payment success on WebView")
                        }
                    }
                }
            })
            
            startActivity(intent)
        } catch (e: Exception) {
            Log.e("VNPaySDK", "Error opening VNPay SDK", e)
            result.error("VNPAY_ERROR", e.message, null)
            currentPaymentCallback = null
        }
    }
    */

    private val paymentResultReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val responseCode = intent?.getStringExtra("responseCode")
            val transactionNo = intent?.getStringExtra("transactionNo")
            val amount = intent?.getStringExtra("amount")
            val orderId = intent?.getStringExtra("orderId")
            val bankCode = intent?.getStringExtra("bankCode")
            val payDate = intent?.getStringExtra("payDate")
            val isSuccess = intent?.getBooleanExtra("isSuccess", false) ?: false

            Log.d("VNPaySDK", "Payment result received: isSuccess=$isSuccess, code=$responseCode")
            
            currentPaymentCallback?.success(mapOf(
                "success" to isSuccess,
                "responseCode" to (responseCode ?: ""),
                "transactionNo" to (transactionNo ?: ""),
                "amount" to (amount ?: ""),
                "orderId" to (orderId ?: ""),
                "bankCode" to (bankCode ?: ""),
                "payDate" to (payDate ?: "")
            ))
            currentPaymentCallback = null
        }
    }

    private fun checkIsEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")
                || "google_sdk" == Build.PRODUCT
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.PRODUCT.contains("sdk")
                || Build.PRODUCT.contains("vbox86")
                || Build.PRODUCT.contains("emulator")
                || Build.PRODUCT.contains("simulator"))
    }

    override fun onDestroy() {
        super.onDestroy()
        LocalBroadcastManager.getInstance(this).unregisterReceiver(paymentResultReceiver)
    }
}
