import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Calendar, ChevronLeft, ChevronRight } from 'lucide-react'
import { Modal } from 'react-bootstrap'

const DateRangePicker = ({ 
  checkinDate, 
  checkoutDate, 
  onDateChange, 
  className = '',
  disabled = false 
}) => {
  const [showPicker, setShowPicker] = useState(false)
  const [currentMonth, setCurrentMonth] = useState(new Date())
  const [selectedStartDate, setSelectedStartDate] = useState(checkinDate ? new Date(checkinDate) : null)
  const [selectedEndDate, setSelectedEndDate] = useState(checkoutDate ? new Date(checkoutDate) : null)
  const [hoverDate, setHoverDate] = useState(null)
  const [isSelectingEndDate, setIsSelectingEndDate] = useState(false)

  useEffect(() => {
    if (checkinDate) setSelectedStartDate(new Date(checkinDate))
    if (checkoutDate) setSelectedEndDate(new Date(checkoutDate))
  }, [checkinDate, checkoutDate])

  const formatDate = (date) => {
    if (!date) return 'Chọn ngày'
    return date.toLocaleDateString('vi-VN', { 
      day: '2-digit', 
      month: '2-digit', 
      year: 'numeric'
    })
  }

  const getDaysInMonth = (date) => {
    const year = date.getFullYear()
    const month = date.getMonth()
    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)
    const daysInMonth = lastDay.getDate()
    const startingDayOfWeek = firstDay.getDay() === 0 ? 7 : firstDay.getDay()

    const days = []
    
    // Empty cells for days before the first day of the month
    for (let i = 1; i < startingDayOfWeek; i++) {
      days.push(null)
    }
    
    // Days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      days.push(new Date(year, month, day))
    }
    
    return days
  }

  const handleDateClick = (date) => {
    if (!date || date < new Date().setHours(0, 0, 0, 0)) return

    if (!selectedStartDate || (selectedStartDate && selectedEndDate)) {
      // Start new selection
      setSelectedStartDate(date)
      setSelectedEndDate(null)
      setIsSelectingEndDate(true)
    } else if (isSelectingEndDate) {
      if (date > selectedStartDate) {
        setSelectedEndDate(date)
        setIsSelectingEndDate(false)
        // Apply changes
        onDateChange({
          checkinDate: selectedStartDate.toISOString().split('T')[0],
          checkoutDate: date.toISOString().split('T')[0]
        })
        setTimeout(() => setShowPicker(false), 300)
      } else {
        // If selected date is before start date, make it the new start date
        setSelectedStartDate(date)
        setSelectedEndDate(null)
      }
    }
  }

  const isDateInRange = (date) => {
    if (!selectedStartDate || !date) return false
    
    const endDate = selectedEndDate || hoverDate
    if (!endDate) return false
    
    return date >= selectedStartDate && date <= endDate
  }

  const isDateSelected = (date) => {
    if (!date) return false
    return (selectedStartDate && date.getTime() === selectedStartDate.getTime()) ||
           (selectedEndDate && date.getTime() === selectedEndDate.getTime())
  }

  const isDateDisabled = (date) => {
    if (!date) return true
    return date < new Date().setHours(0, 0, 0, 0)
  }

  const navigateMonth = (direction) => {
    setCurrentMonth(prev => {
      const newMonth = new Date(prev)
      newMonth.setMonth(prev.getMonth() + direction)
      return newMonth
    })
  }

  return (
    <>
      <motion.div
        className={`date-range-picker-trigger ${className}`}
        onClick={() => !disabled && setShowPicker(true)}
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        style={{
          cursor: disabled ? 'not-allowed' : 'pointer',
          opacity: disabled ? 0.6 : 1
        }}
      >
        <div className="d-flex align-items-center justify-content-between p-3 bg-light rounded-3 border-0">
          <div className="d-flex align-items-center">
            <Calendar size={18} className="text-primary me-2" />
            <div>
              <div className="fw-medium text-dark">
                {formatDate(selectedStartDate)} - {formatDate(selectedEndDate)}
              </div>
              <small className="text-muted">Chọn ngày nhận - trả phòng</small>
            </div>
          </div>
          <motion.div
            animate={{ rotate: showPicker ? 180 : 0 }}
            transition={{ duration: 0.3 }}
          >
            <ChevronRight size={16} className="text-muted" />
          </motion.div>
        </div>
      </motion.div>

      <Modal 
        show={showPicker} 
        onHide={() => setShowPicker(false)} 
        centered
        size="lg"
      >
        <Modal.Header closeButton className="border-0 pb-0">
          <Modal.Title>Chọn ngày nhận và trả phòng</Modal.Title>
        </Modal.Header>
        <Modal.Body className="pt-2">
          <motion.div 
            className="calendar-container"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
          >
            {/* Calendar Header */}
            <div className="d-flex justify-content-between align-items-center mb-4">
              <motion.button
                className="btn btn-outline-primary btn-sm"
                onClick={() => navigateMonth(-1)}
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                <ChevronLeft size={16} />
              </motion.button>
              
              <h5 className="mb-0 fw-bold">
                {currentMonth.toLocaleDateString('vi-VN', { 
                  month: 'long', 
                  year: 'numeric' 
                }).charAt(0).toUpperCase() + currentMonth.toLocaleDateString('vi-VN', { 
                  month: 'long', 
                  year: 'numeric' 
                }).slice(1)}
              </h5>
              
              <motion.button
                className="btn btn-outline-primary btn-sm"
                onClick={() => navigateMonth(1)}
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
              >
                <ChevronRight size={16} />
              </motion.button>
            </div>

            {/* Week Days Header */}
            <div className="row text-center mb-2">
              {['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map(day => (
                <div key={day} className="col text-muted fw-medium small">
                  {day}
                </div>
              ))}
            </div>

            {/* Calendar Grid */}
            <div className="calendar-grid">
              {Array.from({ length: Math.ceil(getDaysInMonth(currentMonth).length / 7) }, (_, weekIndex) => (
                <div key={weekIndex} className="row mb-1">
                  {getDaysInMonth(currentMonth).slice(weekIndex * 7, (weekIndex + 1) * 7).map((date, dayIndex) => (
                    <div key={dayIndex} className="col p-1">
                      {date && (
                        <motion.button
                          className={`
                            w-100 btn btn-sm border-0 rounded-2 position-relative
                            ${isDateSelected(date) ? 'btn-primary text-white' : ''}
                            ${isDateInRange(date) && !isDateSelected(date) ? 'btn-light' : ''}
                            ${isDateDisabled(date) ? 'text-muted' : 'text-dark'}
                          `}
                          style={{
                            height: '40px',
                            background: isDateSelected(date) 
                              ? 'linear-gradient(135deg, #007bff, #0056b3)' 
                              : isDateInRange(date) 
                                ? 'linear-gradient(135deg, rgba(0,123,255,0.1), rgba(0,86,179,0.1))'
                                : 'transparent',
                            boxShadow: isDateSelected(date) ? '0 4px 15px rgba(0,123,255,0.3)' : 'none',
                            cursor: isDateDisabled(date) ? 'not-allowed' : 'pointer'
                          }}
                          onClick={() => handleDateClick(date)}
                          onMouseEnter={() => isSelectingEndDate && setHoverDate(date)}
                          onMouseLeave={() => setHoverDate(null)}
                          disabled={isDateDisabled(date)}
                          whileHover={!isDateDisabled(date) ? { 
                            scale: 1.1,
                            boxShadow: '0 4px 15px rgba(0,123,255,0.2)'
                          } : {}}
                          whileTap={!isDateDisabled(date) ? { scale: 0.95 } : {}}
                          initial={{ scale: 0.8, opacity: 0 }}
                          animate={{ scale: 1, opacity: 1 }}
                          transition={{ 
                            delay: (weekIndex * 7 + dayIndex) * 0.02,
                            duration: 0.3 
                          }}
                        >
                          {date.getDate()}
                          {isDateSelected(date) && (
                            <motion.div
                              className="position-absolute top-0 start-0 w-100 h-100 rounded-2"
                              style={{
                                background: 'linear-gradient(135deg, rgba(255,255,255,0.2), rgba(255,255,255,0.1))',
                                pointerEvents: 'none'
                              }}
                              initial={{ scale: 0 }}
                              animate={{ scale: 1 }}
                              transition={{ duration: 0.3, type: "spring" }}
                            />
                          )}
                        </motion.button>
                      )}
                    </div>
                  ))}
                </div>
              ))}
            </div>

            {/* Selection Status */}
            <AnimatePresence>
              {(selectedStartDate || selectedEndDate) && (
                <motion.div 
                  className="mt-4 p-3 bg-primary bg-opacity-10 rounded-3"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -20 }}
                  transition={{ duration: 0.3 }}
                >
                  <div className="text-center">
                    <div className="fw-bold text-primary mb-1">
                      {selectedStartDate && selectedEndDate ? 'Đã chọn' : 
                       selectedStartDate ? 'Chọn ngày trả phòng' : 'Chọn ngày nhận phòng'}
                    </div>
                    <div className="text-muted">
                      {selectedStartDate && `Nhận: ${formatDate(selectedStartDate)}`}
                      {selectedStartDate && selectedEndDate && ' • '}
                      {selectedEndDate && `Trả: ${formatDate(selectedEndDate)}`}
                    </div>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </Modal.Body>
      </Modal>

      <style>{`
        .date-range-picker-trigger:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        
        .calendar-grid .btn:hover:not(:disabled) {
          transform: scale(1.1);
          transition: all 0.2s ease;
        }
        
        .calendar-grid .btn:active:not(:disabled) {
          transform: scale(0.95);
        }
      `}</style>
    </>
  )
}

export default DateRangePicker