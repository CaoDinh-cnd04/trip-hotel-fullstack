import React, { useState } from 'react'
import { Form, InputGroup, Button, Badge, Alert, Spinner } from 'react-bootstrap'
import { Tag, X, Check, Percent, Gift } from 'lucide-react'
import { discountService } from '../../services/discount/discountService'
import { useAuthStore } from '../../stores/authStore'
import toast from 'react-hot-toast'

const DiscountCodeInput = ({ 
  orderAmount, 
  hotelId, 
  onDiscountApplied, 
  onDiscountRemoved,
  appliedDiscount 
}) => {
  const [discountCode, setDiscountCode] = useState('')
  const [isValidating, setIsValidating] = useState(false)
  const [validationError, setValidationError] = useState('')
  const { user, token } = useAuthStore()

  const handleValidateDiscount = async () => {
    if (!discountCode.trim()) {
      setValidationError('Vui lòng nhập mã giảm giá')
      return
    }

    setIsValidating(true)
    setValidationError('')

    try {
      // Require authentication for discount codes
      if (!token || !user) {
        toast.error('Vui lòng đăng nhập để sử dụng mã giảm giá')
        setProcessing(false)
        return
      }
      
      // Use real API with authentication
      const result = await discountService.validateDiscountCode(discountCode, orderAmount, token)

      if (result.success) {
        // Calculate actual discount amount
        const discountAmount = discountService.calculateDiscountAmount(result.data, orderAmount)
        
        const discountData = {
          ...result.data,
          discountAmount,
          originalAmount: orderAmount,
          finalAmount: orderAmount - discountAmount
        }

        onDiscountApplied(discountData)
        toast.success(`Áp dụng mã giảm giá thành công! Tiết kiệm ${discountAmount.toLocaleString('vi-VN')}₫`)
        setDiscountCode('')
      } else {
        setValidationError(result.message)
        toast.error(result.message)
      }
    } catch (error) {
      console.error('Error validating discount:', error)
      setValidationError('Có lỗi xảy ra khi kiểm tra mã giảm giá')
      toast.error('Có lỗi xảy ra khi kiểm tra mã giảm giá')
    } finally {
      setIsValidating(false)
    }
  }

  const handleRemoveDiscount = () => {
    onDiscountRemoved()
    toast.success('Đã hủy áp dụng mã giảm giá')
  }

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      handleValidateDiscount()
    }
  }

  const formatDiscountDisplay = (discount) => {
    if (!discount) return ''
    
    const isPercentage = discount.discountType?.toLowerCase().includes('percentage') || 
                        discount.discountType?.toLowerCase().includes('phần trăm')
    
    if (isPercentage) {
      return `${discount.discountValue}% OFF`
    } else {
      return `${discount.discountValue.toLocaleString('vi-VN')}₫ OFF`
    }
  }

  if (appliedDiscount) {
    return (
      <div className="discount-applied mb-3">
        <Alert variant="success" className="d-flex align-items-center justify-content-between mb-2">
          <div className="d-flex align-items-center">
            <Check size={16} className="me-2 text-success" />
            <div>
              <strong>{appliedDiscount.code}</strong>
              <div className="small text-muted">{appliedDiscount.description}</div>
            </div>
          </div>
          <Button 
            variant="outline-secondary" 
            size="sm"
            onClick={handleRemoveDiscount}
          >
            <X size={14} />
          </Button>
        </Alert>
        
        <div className="discount-summary p-3 bg-light rounded">
          <div className="d-flex justify-content-between mb-2">
            <span>Tổng tiền phòng:</span>
            <span>{appliedDiscount.originalAmount.toLocaleString('vi-VN')}₫</span>
          </div>
          <div className="d-flex justify-content-between mb-2 text-success">
            <span>
              <Gift size={14} className="me-1" />
              Giảm giá ({formatDiscountDisplay(appliedDiscount)}):
            </span>
            <span>-{appliedDiscount.discountAmount.toLocaleString('vi-VN')}₫</span>
          </div>
          <hr className="my-2" />
          <div className="d-flex justify-content-between fw-bold">
            <span>Thành tiền:</span>
            <span className="text-primary">{appliedDiscount.finalAmount.toLocaleString('vi-VN')}₫</span>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="discount-input mb-3">
      <Form.Label className="fw-semibold">
        <Tag size={16} className="me-2" />
        Mã giảm giá (tùy chọn)
      </Form.Label>
      
      <InputGroup>
        <Form.Control
          type="text"
          placeholder="Nhập mã giảm giá hoặc ưu đãi"
          value={discountCode}
          onChange={(e) => {
            setDiscountCode(e.target.value.toUpperCase())
            setValidationError('')
          }}
          onKeyPress={handleKeyPress}
          disabled={isValidating}
          className={validationError ? 'is-invalid' : ''}
        />
        <Button 
          variant="outline-primary"
          onClick={handleValidateDiscount}
          disabled={isValidating || !discountCode.trim()}
        >
          {isValidating ? (
            <Spinner size="sm" />
          ) : (
            <>
              <Percent size={14} className="me-1" />
              Áp dụng
            </>
          )}
        </Button>
      </InputGroup>
      
      {validationError && (
        <div className="invalid-feedback d-block mt-1">
          {validationError}
        </div>
      )}
      
      <div className="small text-muted mt-2">
        💡 Nhập mã giảm giá của admin hoặc mã ưu đãi từ khách sạn
      </div>
      
      {/* Available discount hints */}
      <div className="available-discounts mt-2">
        <div className="small text-muted mb-1">Mã giảm giá có sẵn:</div>
        <div className="d-flex flex-wrap gap-1">
          <Badge 
            bg="light" 
            text="dark" 
            style={{ cursor: 'pointer' }}
            onClick={() => setDiscountCode('WELCOME20')}
          >
            WELCOME20 - 20% OFF
          </Badge>
          <Badge 
            bg="light" 
            text="dark" 
            style={{ cursor: 'pointer' }}
            onClick={() => setDiscountCode('SAVE50K')}
          >
            SAVE50K - 50K OFF
          </Badge>
          <Badge 
            bg="light" 
            text="dark" 
            style={{ cursor: 'pointer' }}
            onClick={() => setDiscountCode('HOTEL30')}
          >
            HOTEL30 - 30% OFF
          </Badge>
        </div>
      </div>
    </div>
  )
}

export default DiscountCodeInput