// Firebase Setup Script
// Run this in Firebase Console or Firebase CLI to setup initial collections

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./firebase-admin-key.json'); // Download from Firebase Console
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setupFirebaseCollections() {
  console.log('🔥 Setting up Firebase Collections...');

  try {
    // 1. Shop Configuration Collection
    await setupShopConfig();
    
    // 2. Locations Collection  
    await setupLocations();
    
    // 3. Services Collection
    await setupServices();
    
    // 4. Pickup Slots Collection
    await setupPickupSlots();
    
    // 5. Delivery Options Collection
    await setupDeliveryOptions();

    console.log('✅ All collections setup complete!');
  } catch (error) {
    console.error('❌ Setup failed:', error);
  }
}

// Shop Configuration Data
async function setupShopConfig() {
  console.log('📋 Setting up Shop Configuration...');
  
  const shopConfigs = [
    {
      config_key: 'shop_name',
      config_value: 'House of Tailors',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      config_key: 'contact_phone',
      config_value: '+44 123 456 7890',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      config_key: 'contact_email',
      config_value: 'info@houseoftailors.com',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      config_key: 'working_hours',
      config_value: 'Mon-Sat: 9AM-6PM, Sun: 10AM-4PM',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      config_key: 'pickup_fee',
      config_value: 5.99,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      config_key: 'delivery_fee',
      config_value: 8.99,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }
  ];

  const batch = db.batch();
  shopConfigs.forEach((config, index) => {
    const docRef = db.collection('shopConfig').doc(`config_${index + 1}`);
    batch.set(docRef, config);
  });
  
  await batch.commit();
  console.log('✅ Shop Configuration added');
}

// Locations Collection
async function setupLocations() {
  console.log('📍 Setting up Locations...');
  
  const locations = [
    {
      city: 'London',
      town: 'Central London',
      postcode: 'SW1A 1AA',
      isActive: true,
      serviceAvailable: true,
      deliveryFee: 8.99,
      pickupFee: 5.99,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      city: 'London',
      town: 'North London',
      postcode: 'N1',
      isActive: true,
      serviceAvailable: true,
      deliveryFee: 9.99,
      pickupFee: 6.99,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      city: 'London',
      town: 'South London',
      postcode: 'SE1',
      isActive: true,
      serviceAvailable: true,
      deliveryFee: 9.99,
      pickupFee: 6.99,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      city: 'Manchester',
      town: 'City Centre',
      postcode: 'M1',
      isActive: true,
      serviceAvailable: false,
      deliveryFee: 0,
      pickupFee: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }
  ];

  const batch = db.batch();
  locations.forEach((location, index) => {
    const docRef = db.collection('locations').doc(`location_${index + 1}`);
    batch.set(docRef, location);
  });
  
  await batch.commit();
  console.log('✅ Locations added');
}

// Services Collection
async function setupServices() {
  console.log('🛠️ Setting up Services...');
  
  const services = [
    {
      name: 'Hemming',
      description: 'Professional hemming service for trousers, skirts, and dresses',
      category: 'Alterations',
      basePrice: 15.00,
      isActive: true,
      estimatedDays: 3,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      name: 'Taking In/Letting Out',
      description: 'Adjust garment width for perfect fit',
      category: 'Alterations',
      basePrice: 25.00,
      isActive: true,
      estimatedDays: 5,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      name: 'Sleeve Adjustment',
      description: 'Shorten or lengthen sleeves on shirts and jackets',
      category: 'Alterations',
      basePrice: 20.00,
      isActive: true,
      estimatedDays: 4,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      name: 'Zipper Repair',
      description: 'Fix or replace broken zippers',
      category: 'Repairs',
      basePrice: 12.00,
      isActive: true,
      estimatedDays: 2,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      name: 'Button Replacement',
      description: 'Replace missing or damaged buttons',
      category: 'Repairs',
      basePrice: 8.00,
      isActive: true,
      estimatedDays: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      name: 'Cleaning Service',
      description: 'Professional dry cleaning service',
      category: 'Cleaning',
      basePrice: 18.00,
      isActive: true,
      estimatedDays: 2,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }
  ];

  const batch = db.batch();
  services.forEach((service, index) => {
    const docRef = db.collection('services').doc(`service_${index + 1}`);
    batch.set(docRef, service);
  });
  
  await batch.commit();
  console.log('✅ Services added');
}

// Pickup Time Slots
async function setupPickupSlots() {
  console.log('🕐 Setting up Pickup Slots...');
  
  const pickupSlots = [
    {
      timeSlot: '9:00 AM - 11:00 AM',
      isActive: true,
      maxBookings: 5,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      timeSlot: '11:00 AM - 1:00 PM',
      isActive: true,
      maxBookings: 5,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      timeSlot: '1:00 PM - 3:00 PM',
      isActive: true,
      maxBookings: 5,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      timeSlot: '3:00 PM - 5:00 PM',
      isActive: true,
      maxBookings: 5,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      timeSlot: '5:00 PM - 7:00 PM',
      isActive: true,
      maxBookings: 3,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }
  ];

  const batch = db.batch();
  pickupSlots.forEach((slot, index) => {
    const docRef = db.collection('pickupSlots').doc(`slot_${index + 1}`);
    batch.set(docRef, slot);
  });
  
  await batch.commit();
  console.log('✅ Pickup Slots added');
}

// Delivery Options
async function setupDeliveryOptions() {
  console.log('🚚 Setting up Delivery Options...');
  
  const deliveryOptions = [
    {
      method: 'pickup',
      name: 'Pickup from Store',
      description: 'Pick up your items from our store',
      baseFee: 0.00,
      isActive: true,
      estimatedDays: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      method: 'home_pickup',
      name: 'Home Pickup',
      description: 'We collect from your home',
      baseFee: 5.99,
      isActive: true,
      estimatedDays: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      method: 'home_delivery',
      name: 'Home Delivery',
      description: 'We deliver to your home',
      baseFee: 8.99,
      isActive: true,
      estimatedDays: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      method: 'post_delivery',
      name: 'Post Delivery',
      description: 'Delivered via Royal Mail',
      baseFee: 4.99,
      isActive: true,
      estimatedDays: 2,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }
  ];

  const batch = db.batch();
  deliveryOptions.forEach((option, index) => {
    const docRef = db.collection('deliveryOptions').doc(`delivery_${index + 1}`);
    batch.set(docRef, option);
  });
  
  await batch.commit();
  console.log('✅ Delivery Options added');
}

// Run the setup
setupFirebaseCollections();

module.exports = { setupFirebaseCollections };