import React, { useState, useCallback } from 'react'
import { GoogleMap, LoadScript, Marker, InfoWindow } from '@react-google-maps/api'
import { MapPin } from 'lucide-react'

const HotelMap = ({ hotel }) => {
  const [map, setMap] = useState(null)
  const [showInfo, setShowInfo] = useState(true)

  // Default coordinates for major Vietnamese cities
  const cityCoordinates = {
    'TP.HCM': { lat: 10.7769, lng: 106.7009 },
    'Hà Nội': { lat: 21.0285, lng: 105.8542 },
    'Đà Nẵng': { lat: 16.0544, lng: 108.2022 },
    'Nha Trang': { lat: 12.2388, lng: 109.1967 },
    'Phú Quốc': { lat: 10.2899, lng: 103.9864 },
    'Hội An': { lat: 15.8801, lng: 108.3380 },
    'Đà Lạt': { lat: 11.9404, lng: 108.4583 },
    'Huế': { lat: 16.4637, lng: 107.5909 },
    'Thanh Hóa': { lat: 19.8067, lng: 105.7851 }
  }

  // Get coordinates based on hotel city or use geocoding
  const getHotelCoordinates = () => {
    if (hotel?.latitude && hotel?.longitude) {
      return { lat: parseFloat(hotel.latitude), lng: parseFloat(hotel.longitude) }
    }

    // Try to match city name
    const city = hotel?.thanh_pho || hotel?.city || ''
    for (const [cityName, coords] of Object.entries(cityCoordinates)) {
      if (city.includes(cityName) || cityName.includes(city)) {
        return coords
      }
    }

    // Default to Ho Chi Minh City
    return cityCoordinates['TP.HCM']
  }

  const center = getHotelCoordinates()

  const mapContainerStyle = {
    width: '100%',
    height: '400px',
    borderRadius: '12px'
  }

  const options = {
    disableDefaultUI: false,
    zoomControl: true,
    streetViewControl: true,
    mapTypeControl: false,
    fullscreenControl: true,
  }

  const onLoad = useCallback((map) => {
    setMap(map)
  }, [])

  const onUnmount = useCallback(() => {
    setMap(null)
  }, [])

  if (!hotel) {
    return (
      <div style={{ 
        width: '100%', 
        height: '400px', 
        backgroundColor: '#f0f0f0', 
        borderRadius: '12px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#999'
      }}>
        Đang tải bản đồ...
      </div>
    )
  }

  // Get hotel name and address properly
  const hotelName = hotel.ten_khach_san || hotel.ten || hotel.name || 'Khách sạn'
  const hotelAddress = hotel.dia_chi || hotel.address || ''

  return (
    <LoadScript googleMapsApiKey={import.meta.env.VITE_GOOGLE_MAPS_API_KEY || 'AIzaSyDummy-Key-Replace-With-Your-Key'}>
      <GoogleMap
        mapContainerStyle={mapContainerStyle}
        center={center}
        zoom={15}
        options={options}
        onLoad={onLoad}
        onUnmount={onUnmount}
      >
        <Marker
          position={center}
          animation={window.google?.maps?.Animation?.DROP}
          onClick={() => setShowInfo(!showInfo)}
        />

        {showInfo && (
          <InfoWindow
            position={center}
            onCloseClick={() => setShowInfo(false)}
          >
            <div style={{ padding: '10px', minWidth: '200px' }}>
              <h6 style={{ margin: '0 0 8px 0', fontWeight: 'bold', color: '#333' }}>
                {hotelName}
              </h6>
              {hotelAddress && (
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: '6px', color: '#666', fontSize: '14px' }}>
                  <MapPin size={16} style={{ marginTop: '2px', flexShrink: 0 }} />
                  <span>{hotelAddress}</span>
                </div>
              )}
              {(hotel.danh_gia || hotel.rating) && (
                <div style={{ marginTop: '8px', fontSize: '13px', color: '#ffa500' }}>
                  ⭐ {hotel.danh_gia || hotel.rating} ({hotel.so_luong_danh_gia || hotel.reviews_count || 0} đánh giá)
                </div>
              )}
            </div>
          </InfoWindow>
        )}
      </GoogleMap>
    </LoadScript>
  )
}

export default HotelMap
