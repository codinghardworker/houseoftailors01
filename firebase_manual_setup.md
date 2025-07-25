# Firebase Manual Setup Guide

Since you may not have Firebase Admin SDK setup, here's how to manually add the collections in Firebase Console:

## 1. ShopConfig Collection

Go to Firestore Database → Start a collection → Name: `shopConfig`

Add these documents:

### Document: `config_1`
```json
{
  "config_key": "shop_name",
  "config_value": "House of Tailors",
  "isActive": true,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `config_2`
```json
{
  "config_key": "contact_phone",
  "config_value": "+44 123 456 7890",
  "isActive": true,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `config_3`
```json
{
  "config_key": "contact_email",
  "config_value": "info@houseoftailors.com",
  "isActive": true,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `config_4`
```json
{
  "config_key": "working_hours",
  "config_value": "Mon-Sat: 9AM-6PM, Sun: 10AM-4PM",
  "isActive": true,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `config_5`
```json
{
  "config_key": "pickup_fee",
  "config_value": 5.99,
  "isActive": true,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `config_6`
```json
{
  "config_key": "delivery_fee",
  "config_value": 8.99,
  "isActive": true,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

## 2. Locations Collection

Create collection: `locations`

### Document: `location_1`
```json
{
  "city": "London",
  "town": "Central London",
  "postcode": "SW1A 1AA",
  "isActive": true,
  "serviceAvailable": true,
  "deliveryFee": 8.99,
  "pickupFee": 5.99,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `location_2`
```json
{
  "city": "London",
  "town": "North London",
  "postcode": "N1",
  "isActive": true,
  "serviceAvailable": true,
  "deliveryFee": 9.99,
  "pickupFee": 6.99,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `location_3`
```json
{
  "city": "London",
  "town": "South London",
  "postcode": "SE1",
  "isActive": true,
  "serviceAvailable": true,
  "deliveryFee": 9.99,
  "pickupFee": 6.99,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `location_4`
```json
{
  "city": "Manchester",
  "town": "City Centre",
  "postcode": "M1",
  "isActive": true,
  "serviceAvailable": false,
  "deliveryFee": 0,
  "pickupFee": 0,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

## 3. Services Collection

Create collection: `services`

### Document: `service_1`
```json
{
  "name": "Hemming",
  "description": "Professional hemming service for trousers, skirts, and dresses",
  "category": "Alterations",
  "basePrice": 15.00,
  "isActive": true,
  "estimatedDays": 3,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `service_2`
```json
{
  "name": "Taking In/Letting Out",
  "description": "Adjust garment width for perfect fit",
  "category": "Alterations",
  "basePrice": 25.00,
  "isActive": true,
  "estimatedDays": 5,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `service_3`
```json
{
  "name": "Sleeve Adjustment",
  "description": "Shorten or lengthen sleeves on shirts and jackets",
  "category": "Alterations",
  "basePrice": 20.00,
  "isActive": true,
  "estimatedDays": 4,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `service_4`
```json
{
  "name": "Zipper Repair",
  "description": "Fix or replace broken zippers",
  "category": "Repairs",
  "basePrice": 12.00,
  "isActive": true,
  "estimatedDays": 2,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `service_5`
```json
{
  "name": "Button Replacement",
  "description": "Replace missing or damaged buttons",
  "category": "Repairs",
  "basePrice": 8.00,
  "isActive": true,
  "estimatedDays": 1,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `service_6`
```json
{
  "name": "Cleaning Service",
  "description": "Professional dry cleaning service",
  "category": "Cleaning",
  "basePrice": 18.00,
  "isActive": true,
  "estimatedDays": 2,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

## 4. PickupSlots Collection

Create collection: `pickupSlots`

### Document: `slot_1`
```json
{
  "timeSlot": "9:00 AM - 11:00 AM",
  "isActive": true,
  "maxBookings": 5,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `slot_2`
```json
{
  "timeSlot": "11:00 AM - 1:00 PM",
  "isActive": true,
  "maxBookings": 5,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `slot_3`
```json
{
  "timeSlot": "1:00 PM - 3:00 PM",
  "isActive": true,
  "maxBookings": 5,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `slot_4`
```json
{
  "timeSlot": "3:00 PM - 5:00 PM",
  "isActive": true,
  "maxBookings": 5,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `slot_5`
```json
{
  "timeSlot": "5:00 PM - 7:00 PM",
  "isActive": true,
  "maxBookings": 3,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

## 5. DeliveryOptions Collection

Create collection: `deliveryOptions`

### Document: `delivery_1`
```json
{
  "method": "pickup",
  "name": "Pickup from Store",
  "description": "Pick up your items from our store",
  "baseFee": 0.00,
  "isActive": true,
  "estimatedDays": 0,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `delivery_2`
```json
{
  "method": "home_pickup",
  "name": "Home Pickup",
  "description": "We collect from your home",
  "baseFee": 5.99,
  "isActive": true,
  "estimatedDays": 0,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `delivery_3`
```json
{
  "method": "home_delivery",
  "name": "Home Delivery",
  "description": "We deliver to your home",
  "baseFee": 8.99,
  "isActive": true,
  "estimatedDays": 1,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

### Document: `delivery_4`
```json
{
  "method": "post_delivery",
  "name": "Post Delivery",
  "description": "Delivered via Royal Mail",
  "baseFee": 4.99,
  "isActive": true,
  "estimatedDays": 2,
  "createdAt": "2025-01-25T11:34:00Z",
  "updatedAt": "2025-01-25T11:34:00Z"
}
```

## Important Notes:

1. **Data Types**: Make sure to use correct data types:
   - `isActive`: boolean
   - `serviceAvailable`: boolean  
   - `basePrice`, `deliveryFee`, `pickupFee`, `baseFee`: number
   - `estimatedDays`, `maxBookings`: number
   - All other fields: string

2. **Timestamps**: You can use Firebase Console's timestamp feature or current date

3. **Collections Order**: Add collections in this order as some services depend on others

4. **Test Data**: This is sample data - modify according to your actual business needs