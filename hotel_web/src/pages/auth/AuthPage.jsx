import React, { useState, useEffect } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { Container, Row, Col, Card, Form, Button, InputGroup, Alert, Spinner } from 'react-bootstrap'
import { Eye, EyeOff, Mail, Lock, User, Phone, Shield, Building2 } from 'lucide-react'
import { useAuthStore } from '../../stores/authStore'
import toast from 'react-hot-toast'

const AuthPage = () => {
  const location = useLocation()
  // Kiểm tra URL để xác định hiển thị form đăng nhập hay đăng ký
  // Nếu path là /register thì hiển thị form đăng ký (isLogin = false)
  const [isLogin, setIsLogin] = useState(location.pathname !== '/register')
  
  // Cập nhật isLogin khi URL thay đổi
  useEffect(() => {
    setIsLogin(location.pathname !== '/register')
  }, [location.pathname])
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  
  const { login, register, isLoading, error } = useAuthStore()
  const navigate = useNavigate()

  // Login form data
  const [loginData, setLoginData] = useState({
    email: '',
    password: ''
  })

  // Register form data  
  const [registerData, setRegisterData] = useState({
    ho_ten: '',
    email: '',
    so_dien_thoai: '',
    password: '',
    confirmPassword: '',
    gioi_tinh: 'Nam'
  })

  const handleLogin = async (e) => {
    e.preventDefault()
    
    if (!loginData.email || !loginData.password) {
      toast.error('Vui lòng điền đầy đủ thông tin')
      return
    }

    const result = await login({
      email: loginData.email,
      mat_khau: loginData.password
    })

    if (result.success) {
      toast.success('Đăng nhập thành công!')
      navigate('/')
    } else {
      toast.error(result.error)
    }
  }

  const handleRegister = async (e) => {
    e.preventDefault()
    
    // Validation
    if (!registerData.ho_ten || !registerData.email || !registerData.password) {
      toast.error('Vui lòng điền đầy đủ thông tin')
      return
    }

    if (registerData.ho_ten.length < 2 || registerData.ho_ten.length > 100) {
      toast.error('Họ tên phải từ 2-100 ký tự')
      return
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(registerData.email)) {
      toast.error('Email không hợp lệ')
      return
    }

    // Phone validation (10-11 digits)
    if (registerData.so_dien_thoai && !/^[0-9]{10,11}$/.test(registerData.so_dien_thoai)) {
      toast.error('Số điện thoại phải có 10-11 chữ số')
      return
    }

    if (registerData.password !== registerData.confirmPassword) {
      toast.error('Mật khẩu xác nhận không khớp')
      return
    }

    if (registerData.password.length < 6) {
      toast.error('Mật khẩu phải có ít nhất 6 ký tự')
      return
    }

    // Password must contain at least 1 uppercase, 1 lowercase, and 1 number
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/
    if (!passwordRegex.test(registerData.password)) {
      toast.error('Mật khẩu phải chứa ít nhất 1 chữ hoa, 1 chữ thường và 1 số')
      return
    }

    const result = await register({
      ho_ten: registerData.ho_ten,
      email: registerData.email,
      sdt: registerData.so_dien_thoai || '', // Backend expect 'sdt' not 'so_dien_thoai'
      mat_khau: registerData.password,
      gioi_tinh: registerData.gioi_tinh
    })

    if (result.success) {
      toast.success('Đăng ký thành công!')
      navigate('/')
    } else {
      toast.error(result.error)
    }
  }

  return (
    <div className="min-vh-100 bg-light d-flex align-items-center py-5">
      <Container>
        <Row className="justify-content-center">
          <Col md={6} lg={5}>
            <Card className="shadow-sm border-0">
              <Card.Body className="p-5">
                {/* Header */}
                <div className="text-center mb-4">
                  <Link to="/" className="text-decoration-none">
                    <div className="d-flex align-items-center justify-content-center mb-3">
                      <div className="bg-primary text-white rounded p-2 me-2">
                        <strong>T</strong>
                      </div>
                      <h3 className="mb-0 text-dark">TripHotel</h3>
                    </div>
                  </Link>
                  <h4 className="mb-2">{isLogin ? 'Đăng nhập' : 'Đăng ký tài khoản'}</h4>
                  <p className="text-muted">
                    {isLogin 
                      ? 'Tạo tài khoản để bắt đầu đặt phòng' 
                      : 'Chào mừng bạn quay trở lại!'
                    }
                  </p>
                </div>

                {/* Error Alert */}
                {error && (
                  <Alert variant="danger" className="mb-4">
                    {error}
                  </Alert>
                )}

                {/* Login Form */}
                {isLogin ? (
                  <Form onSubmit={handleLogin}>
                    <Form.Group className="mb-3">
                      <Form.Label>Email</Form.Label>
                      <InputGroup>
                        <InputGroup.Text>
                          <Mail size={18} />
                        </InputGroup.Text>
                        <Form.Control
                          type="email"
                          placeholder="Nhập email của bạn"
                          value={loginData.email}
                          onChange={(e) => setLoginData({...loginData, email: e.target.value})}
                          required
                        />
                      </InputGroup>
                    </Form.Group>

                    <Form.Group className="mb-4">
                      <Form.Label>Mật khẩu</Form.Label>
                      <InputGroup>
                        <InputGroup.Text>
                          <Lock size={18} />
                        </InputGroup.Text>
                        <Form.Control
                          type={showPassword ? 'text' : 'password'}
                          placeholder="Nhập mật khẩu"
                          value={loginData.password}
                          onChange={(e) => setLoginData({...loginData, password: e.target.value})}
                          required
                        />
                        <Button
                          variant="outline-secondary"
                          onClick={() => setShowPassword(!showPassword)}
                        >
                          {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                        </Button>
                      </InputGroup>
                    </Form.Group>

                    <Button 
                      type="submit" 
                      variant="primary" 
                      size="lg" 
                      className="w-100 mb-3"
                      disabled={isLoading}
                    >
                      {isLoading ? (
                        <>
                          <Spinner animation="border" size="sm" className="me-2" />
                          Đang đăng nhập...
                        </>
                      ) : (
                        'Đăng nhập'
                      )}
                    </Button>
                  </Form>
                ) : (
                  /* Register Form */
                  <Form onSubmit={handleRegister}>
                    <Form.Group className="mb-3">
                      <Form.Label>Họ tên</Form.Label>
                      <InputGroup>
                        <InputGroup.Text>
                          <User size={18} />
                        </InputGroup.Text>
                        <Form.Control
                          type="text"
                          placeholder="Nhập họ tên của bạn"
                          value={registerData.ho_ten}
                          onChange={(e) => setRegisterData({...registerData, ho_ten: e.target.value})}
                          required
                        />
                      </InputGroup>
                    </Form.Group>

                    <Form.Group className="mb-3">
                      <Form.Label>Email</Form.Label>
                      <InputGroup>
                        <InputGroup.Text>
                          <Mail size={18} />
                        </InputGroup.Text>
                        <Form.Control
                          type="email"
                          placeholder="Nhập email của bạn"
                          value={registerData.email}
                          onChange={(e) => setRegisterData({...registerData, email: e.target.value})}
                          required
                        />
                      </InputGroup>
                    </Form.Group>

                    <Form.Group className="mb-3">
                      <Form.Label>Số điện thoại</Form.Label>
                      <InputGroup>
                        <InputGroup.Text>
                          <Phone size={18} />
                        </InputGroup.Text>
                        <Form.Control
                          type="tel"
                          placeholder="Nhập số điện thoại"
                          value={registerData.so_dien_thoai}
                          onChange={(e) => setRegisterData({...registerData, so_dien_thoai: e.target.value})}
                        />
                      </InputGroup>
                    </Form.Group>

                    <Form.Group className="mb-3">
                      <Form.Label>Giới tính</Form.Label>
                      <Form.Select
                        value={registerData.gioi_tinh}
                        onChange={(e) => setRegisterData({...registerData, gioi_tinh: e.target.value})}
                      >
                        <option value="Nam">Nam</option>
                        <option value="Nữ">Nữ</option>
                      </Form.Select>
                    </Form.Group>

                    <Form.Group className="mb-3">
                      <Form.Label>Mật khẩu</Form.Label>
                      <InputGroup>
                        <InputGroup.Text>
                          <Lock size={18} />
                        </InputGroup.Text>
                        <Form.Control
                          type={showPassword ? 'text' : 'password'}
                          placeholder="Nhập mật khẩu"
                          value={registerData.password}
                          onChange={(e) => setRegisterData({...registerData, password: e.target.value})}
                          required
                        />
                        <Button
                          variant="outline-secondary"
                          onClick={() => setShowPassword(!showPassword)}
                        >
                          {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                        </Button>
                      </InputGroup>
                      <Form.Text className="text-muted">
                        Mật khẩu phải có ít nhất 6 ký tự, bao gồm 1 chữ hoa, 1 chữ thường và 1 số
                      </Form.Text>
                    </Form.Group>

                    <Form.Group className="mb-4">
                      <Form.Label>Xác nhận mật khẩu</Form.Label>
                      <InputGroup>
                        <InputGroup.Text>
                          <Lock size={18} />
                        </InputGroup.Text>
                        <Form.Control
                          type={showConfirmPassword ? 'text' : 'password'}
                          placeholder="Nhập lại mật khẩu"
                          value={registerData.confirmPassword}
                          onChange={(e) => setRegisterData({...registerData, confirmPassword: e.target.value})}
                          required
                        />
                        <Button
                          variant="outline-secondary"
                          onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        >
                          {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                        </Button>
                      </InputGroup>
                    </Form.Group>

                    <Button 
                      type="submit" 
                      variant="primary" 
                      size="lg" 
                      className="w-100 mb-3"
                      disabled={isLoading}
                    >
                      {isLoading ? (
                        <>
                          <Spinner animation="border" size="sm" className="me-2" />
                          Đang đăng ký...
                        </>
                      ) : (
                        'Đăng ký'
                      )}
                    </Button>
                  </Form>
                )}

                {/* Toggle Login/Register */}
                <div className="text-center">
                  <p className="mb-0">
                    {isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? '}
                    <Link 
                      to={isLogin ? '/register' : '/login'}
                      className="text-decoration-none"
                    >
                      {isLogin ? 'Đăng ký ngay' : 'Đăng nhập'}
                    </Link>
                  </p>
                </div>

                {/* Admin/Manager Login Links */}
                {isLogin && (
                  <div className="mt-4 pt-3 border-top">
                    <p className="text-center text-muted small mb-2">Đăng nhập với tư cách:</p>
                    <div className="d-flex gap-2 justify-content-center">
                      <Link 
                        to="/admin/login" 
                        className="btn btn-outline-primary btn-sm d-flex align-items-center"
                      >
                        <Shield size={16} className="me-1" />
                        Admin
                      </Link>
                      <Link 
                        to="/manager/login" 
                        className="btn btn-outline-success btn-sm d-flex align-items-center"
                      >
                        <Building2 size={16} className="me-1" />
                        Manager
                      </Link>
                    </div>
                  </div>
                )}
              </Card.Body>
            </Card>
          </Col>
        </Row>
      </Container>
    </div>
  )
}

export default AuthPage