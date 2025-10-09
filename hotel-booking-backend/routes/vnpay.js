const express = require('express');
const router = express.Router();
const querystring = require('qs');
const crypto = require('crypto');

router.post('/create', (req, res) => {
    const { amount, orderId, orderInfo, returnUrl } = req.body;

    const vnp_TmnCode = "NJJ0R8FS";
    const vnp_HashSecret = "BYKJBHPPZKQMKBIBGGXIYKWYFAYSJXCW";
    const vnp_Url = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
    const vnp_ReturnUrl = returnUrl;

    const vnp_TxnRef = orderId;
    const vnp_OrderInfo = orderInfo;
    const vnp_OrderType = 'other';
    const vnp_Amount = amount * 100; // VNPAY yêu cầu đơn vị là VND * 100
    const vnp_Locale = 'vn';
    const vnp_BankCode = '';
    const vnp_IpAddr = req.ip;

    let vnp_Params = {
        'vnp_Version': '2.1.0',
        'vnp_Command': 'pay',
        'vnp_TmnCode': vnp_TmnCode,
        'vnp_Locale': vnp_Locale,
        'vnp_CurrCode': 'VND',
        'vnp_TxnRef': vnp_TxnRef,
        'vnp_OrderInfo': vnp_OrderInfo,
        'vnp_OrderType': vnp_OrderType,
        'vnp_Amount': vnp_Amount,
        'vnp_ReturnUrl': vnp_ReturnUrl,
        'vnp_IpAddr': vnp_IpAddr,
        'vnp_CreateDate': new Date().toISOString().replace(/[-:TZ.]/g, '').slice(0, 14)
    };

    vnp_Params = sortObject(vnp_Params);

    const signData = querystring.stringify(vnp_Params, { encode: false });
    const hmac = crypto.createHmac("sha512", vnp_HashSecret);
    const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");
    vnp_Params['vnp_SecureHash'] = signed;

    const paymentUrl = vnp_Url + '?' + querystring.stringify(vnp_Params, { encode: true });
    res.json({ payUrl: paymentUrl });
});

function sortObject(obj) {
    const sorted = {};
    const keys = Object.keys(obj).sort();
    for (let key of keys) {
        sorted[key] = obj[key];
    }
    return sorted;
}

module.exports = router;