import React from 'react'
import { clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

const cn = (...inputs) => {
  return twMerge(clsx(inputs))
}

const Skeleton = ({ className, ...props }) => {
  return (
    <div
      className={cn("animate-pulse rounded-md bg-gray-200", className)}
      {...props}
    />
  )
}

const SkeletonCard = ({ className }) => (
  <div className={cn("p-4 space-y-3", className)}>
    <Skeleton className="h-4 w-2/3" />
    <Skeleton className="h-4 w-full" />
    <Skeleton className="h-4 w-1/2" />
  </div>
)

const SkeletonHotelCard = () => (
  <div className="bg-white rounded-lg shadow-md overflow-hidden">
    <Skeleton className="h-48 w-full" />
    <div className="p-4 space-y-3">
      <Skeleton className="h-6 w-3/4" />
      <Skeleton className="h-4 w-1/2" />
      <div className="flex justify-between items-center">
        <Skeleton className="h-4 w-16" />
        <Skeleton className="h-6 w-20" />
      </div>
    </div>
  </div>
)

export { Skeleton, SkeletonCard, SkeletonHotelCard }