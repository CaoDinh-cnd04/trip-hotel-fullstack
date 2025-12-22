import React, { useState } from 'react'
import { useQuery } from 'react-query'
import { motion } from 'framer-motion'
import { Star, TrendingUp, Gift, Award, Crown, CheckCircle } from 'lucide-react'
import { userAPI } from '../../services/api/user'
import toast from 'react-hot-toast'

const TriphotelVipPage = () => {
  const { data: vipInfo, isLoading } = useQuery(
    'vip-status',
    async () => {
      try {
        const response = await userAPI.getVipStatus()
        return response.data || {
          vipLevel: 'Bronze',
          vipPoints: 0,
          nextLevelPoints: 1000,
          progressToNextLevel: 0,
          benefits: []
        }
      } catch (error) {
        console.error('Error fetching VIP status:', error)
        return {
          vipLevel: 'Bronze',
          vipPoints: 0,
          nextLevelPoints: 1000,
          progressToNextLevel: 0,
          benefits: []
        }
      }
    }
  )

  const getLevelInfo = (level) => {
    switch (level) {
      case 'Diamond':
        return { 
          name: 'Kim Cương', 
          color: 'cyan', 
          minPoints: 10000,
          bgGradient: 'from-cyan-600 to-cyan-400',
          bgColor: 'bg-cyan-600',
          bgLight: 'bg-cyan-50',
          borderColor: 'border-cyan-500',
          textColor: 'text-cyan-600'
        }
      case 'Gold':
        return { 
          name: 'Vàng', 
          color: 'amber', 
          minPoints: 5000,
          bgGradient: 'from-amber-600 to-amber-400',
          bgColor: 'bg-amber-600',
          bgLight: 'bg-amber-50',
          borderColor: 'border-amber-500',
          textColor: 'text-amber-600'
        }
      case 'Silver':
        return { 
          name: 'Bạc', 
          color: 'gray', 
          minPoints: 1000,
          bgGradient: 'from-gray-600 to-gray-400',
          bgColor: 'bg-gray-600',
          bgLight: 'bg-gray-50',
          borderColor: 'border-gray-500',
          textColor: 'text-gray-600'
        }
      default:
        return { 
          name: 'Đồng', 
          color: 'brown', 
          minPoints: 0,
          bgGradient: 'from-amber-800 to-amber-600',
          bgColor: 'bg-amber-800',
          bgLight: 'bg-amber-50',
          borderColor: 'border-amber-500',
          textColor: 'text-amber-600'
        }
    }
  }

  const formatPoints = (points) => {
    if (points >= 1000000) return `${(points / 1000000).toFixed(1)}M`
    if (points >= 1000) return `${(points / 1000).toFixed(1)}K`
    return points.toString()
  }

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Đang tải thông tin VIP...</p>
        </div>
      </div>
    )
  }

  const levelInfo = getLevelInfo(vipInfo?.vipLevel || 'Bronze')
  const nextLevel = vipInfo?.vipLevel === 'Bronze' ? 'Silver' : 
                    vipInfo?.vipLevel === 'Silver' ? 'Gold' : 
                    vipInfo?.vipLevel === 'Gold' ? 'Diamond' : 'Diamond'
  const nextLevelInfo = getLevelInfo(nextLevel)

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header với gradient theo level */}
      <div className={`bg-gradient-to-br ${levelInfo.bgGradient} text-white`}>
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-12">
          <div className="text-center">
            <div className="inline-flex items-center gap-3 bg-white/20 backdrop-blur-sm px-6 py-3 rounded-xl mb-6 border-2 border-white/30">
              <Star size={28} className="text-yellow-300" />
              <span className="text-2xl font-bold">VIP {levelInfo.name}</span>
            </div>
            <p className="text-white/90 mb-4">Điểm hiện tại</p>
            <p className="text-5xl font-bold mb-2">{formatPoints(vipInfo?.vipPoints || 0)}</p>
            <p className="text-white/80 text-sm">Điểm tích lũy</p>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 -mt-8 pb-8">
        {/* Progress Card */}
        {vipInfo?.nextLevelPoints && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-xl shadow-sm p-6 mb-6"
          >
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900">
                Tiến độ đến {nextLevelInfo.name}
              </h3>
              <span className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm font-medium">
                {vipInfo.progressToNextLevel || 0}%
              </span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-3 mb-3">
              <div
                className={`h-3 rounded-full ${nextLevelInfo.bgColor}`}
                style={{ width: `${vipInfo.progressToNextLevel || 0}%` }}
              ></div>
            </div>
            <div className="flex items-center justify-between text-sm text-gray-600">
              <span>
                {formatPoints((vipInfo.vipPoints || 0) - levelInfo.minPoints)} / {formatPoints(vipInfo.nextLevelPoints - levelInfo.minPoints)}
              </span>
              <span className="font-medium">
                Còn {formatPoints(vipInfo.nextLevelPoints - (vipInfo.vipPoints || 0))} điểm
              </span>
            </div>
          </motion.div>
        )}

        {/* Levels Overview */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-xl shadow-sm p-6 mb-6"
        >
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Các hạng thành viên</h3>
          <div className="space-y-3">
            {[
              { level: 'Bronze', name: 'Đồng', minPoints: 0, ...getLevelInfo('Bronze') },
              { level: 'Silver', name: 'Bạc', minPoints: 1000, ...getLevelInfo('Silver') },
              { level: 'Gold', name: 'Vàng', minPoints: 5000, ...getLevelInfo('Gold') },
              { level: 'Diamond', name: 'Kim Cương', minPoints: 10000, ...getLevelInfo('Diamond') }
            ].map((level) => {
              const isCurrent = (vipInfo?.vipLevel || 'Bronze') === level.level
              const isUnlocked = (vipInfo?.vipPoints || 0) >= level.minPoints
              
              return (
                <div
                  key={level.level}
                  className={`p-4 rounded-lg border-2 ${
                    isCurrent
                      ? `${level.bgLight} ${level.borderColor}`
                      : 'bg-gray-50 border-gray-200'
                  }`}
                >
                  <div className="flex items-center gap-4">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                      isUnlocked ? level.bgColor : 'bg-gray-300'
                    }`}>
                      <Star size={20} className="text-white" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className="font-semibold text-gray-900">{level.name}</span>
                        {isCurrent && (
                          <span className="px-2 py-0.5 bg-blue-600 text-white text-xs rounded font-medium">
                            HIỆN TẠI
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-gray-500">Từ {formatPoints(level.minPoints)} điểm</p>
                    </div>
                    {isUnlocked && (
                      <CheckCircle size={20} className={level.textColor} />
                    )}
                  </div>
                </div>
              )
            })}
          </div>
        </motion.div>

        {/* Benefits */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-xl shadow-sm p-6"
        >
          <div className="flex items-center gap-3 mb-4">
            <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${levelInfo.bgLight}`}>
              <Gift size={20} className={levelInfo.textColor} />
            </div>
            <h3 className="text-lg font-semibold text-gray-900">
              Quyền lợi {levelInfo.name}
            </h3>
          </div>
          <div className="space-y-3">
            {(vipInfo?.benefits || [
              'Giảm giá đặc biệt cho thành viên',
              'Ưu tiên hỗ trợ khách hàng',
              'Tích điểm thưởng cho mỗi đặt phòng',
              'Nhận thông báo về ưu đãi độc quyền'
            ]).map((benefit, index) => (
              <div key={index} className="flex items-start gap-3">
                <div className={`w-2 h-2 rounded-full mt-2 ${levelInfo.bgColor}`}></div>
                <p className="text-gray-700 flex-1">{benefit}</p>
              </div>
            ))}
          </div>
        </motion.div>
      </div>
    </div>
  )
}

export default TriphotelVipPage

