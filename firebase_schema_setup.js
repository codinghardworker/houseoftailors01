// Firebase Schema Setup - Matching SQL Structure for House of Tailors
// Run this to setup Firestore collections matching your SQL database

const admin = require('firebase-admin');

// Initialize Firebase Admin (comment out if already initialized)
const serviceAccount = require('./houseoftailors1-786c5-firebase-adminsdk-fbsvc-ce745cd85c.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setupHouseOfTailorsSchema() {
  console.log('🔥 Setting up House of Tailors Firebase Schema...');

  try {
    // 1. Shop Configuration (matches shop_config table)
    await setupShopConfig();
    
    // 2. Orders Collection (matches orders table)
    await setupOrdersCollection();
    
    // 3. Loyalty Progress (matches loyalty_progress table)
    await setupLoyaltyProgress();
    
    // 4. Service Requests (matches service_requests table)
    await setupServiceRequests();

    console.log('✅ Firebase Schema Setup Complete!');
  } catch (error) {
    console.error('❌ Schema setup failed:', error);
  }
}

// 1. Shop Configuration Collection - matches shop_config table structure
async function setupShopConfig() {
  console.log('📋 Setting up Shop Configuration...');
  
  const shopConfigs = [
    {
      config_key: 'shop_info',
      config_value: {
        name: "House of Tailors",
        address_line1: "123 Tailor Street",
        address_line2: "Suite 456",
        city: "London",
        postal_code: "SW1A 1AA",
        country: "United Kingdom",
        phone: "+44 20 1234 5678",
        email: "info@houseoftailors.com"
      },
      description: 'Basic shop information and address',
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      config_key: 'delivery_options',
      config_value: {
        pickup_charge_pence: 1000,
        post_delivery_charge_pence: 0,
        free_delivery_threshold_pence: 5000,
        currency: "GBP",
        available_methods: ["pickup", "post"]
      },
      description: 'Available delivery methods and charges in pence',
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      config_key: 'pickup_slots',
      config_value: {
        monday: { available_slots: ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM", "3:00 PM - 4:00 PM", "4:00 PM - 5:00 PM"] },
        tuesday: { available_slots: ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM", "3:00 PM - 4:00 PM", "4:00 PM - 5:00 PM"] },
        wednesday: { available_slots: ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM", "3:00 PM - 4:00 PM", "4:00 PM - 5:00 PM"] },
        thursday: { available_slots: ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM", "3:00 PM - 4:00 PM", "4:00 PM - 5:00 PM"] },
        friday: { available_slots: ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM", "3:00 PM - 4:00 PM", "4:00 PM - 5:00 PM"] },
        saturday: { available_slots: ["10:00 AM - 11:00 AM", "11:00 AM - 12:00 PM", "12:00 PM - 1:00 PM", "2:00 PM - 3:00 PM"] },
        sunday: { available_slots: [] }
      },
      description: 'Available pickup time slots by day with 12-hour format',
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      config_key: 'available_locations',
      config_value: {
        cities: [
          {
            id: "london",
            name: "London",
            towns: [
              "Westminster", "Camden", "Islington", "Hackney", "Tower Hamlets",
              "Greenwich", "Lewisham", "Southwark", "Lambeth", "Wandsworth",
              "Hammersmith and Fulham", "Kensington and Chelsea", "Brent",
              "Ealing", "Hounslow", "Richmond upon Thames", "Kingston upon Thames",
              "Merton", "Sutton", "Croydon", "Bromley", "Bexley", "Havering",
              "Barking and Dagenham", "Redbridge", "Newham", "Waltham Forest",
              "Haringey", "Enfield", "Barnet", "Harrow", "Hillingdon"
            ]
          },
          {
            id: "newcastle",
            name: "Newcastle",
            towns: [
              "City Centre", "Gosforth", "Jesmond", "Heaton", "Walker",
              "Byker", "Felling", "Gateshead", "Low Fell", "Whickham",
              "Blaydon", "Ryton", "Crawcrook", "Prudhoe", "Hexham",
              "Corbridge", "Ponteland", "Cramlington", "Blyth", "Ashington",
              "Morpeth", "Alnwick", "Berwick-upon-Tweed"
            ]
          }
        ]
      },
      description: 'Available cities and their towns for location selection',
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    }
  ];

  const batch = db.batch();
  shopConfigs.forEach((config, index) => {
    const docRef = db.collection('shopConfig').doc(`config_${config.config_key}`);
    batch.set(docRef, config);
  });
  
  await batch.commit();
  console.log('✅ Shop Configuration added');
}

// 2. Orders Collection Structure (no initial data, just setup collection)
async function setupOrdersCollection() {
  console.log('📦 Setting up Orders Collection structure...');
  
  // Create a sample order structure (to be deleted after setup)
  const sampleOrder = {
    // Structure matches SQL orders table
    user_id: 'sample_user_id', // Will be replaced with actual Firebase Auth UID
    payment_intent_id: 'pi_sample_payment_intent',
    total_amount: 45.99,
    currency: 'gbp',
    status: 'pickup', // pickup, processing, completed
    delivery_method: 'pickup', // pickup, post
    delivery_info: {
      pickup_date: '2025-01-30',
      pickup_time: '10:00 AM - 11:00 AM',
      pickup_cost: 10.00
    },
    billing_address: {
      line1: '123 Customer Street',
      city: 'London',
      postal_code: 'SW1A 1AA',
      country: 'GB'
    },
    customer_name: 'Sample Customer',
    customer_email: 'customer@example.com',
    customer_phone: '+44 20 1234 5678',
    order_items: [
      {
        itemId: 'item_1',
        itemName: 'Dress Shirt',
        itemDescription: 'Blue cotton dress shirt',
        itemCategory: {
          id: 'shirts',
          name: 'Shirts'
        },
        services: [
          {
            serviceId: 'hemming',
            serviceName: 'Hemming',
            basePrice: 15.00,
            totalPrice: 15.00,
            tailorNotes: 'Hem to 32 inches',
            fittingChoice: 'perfect_fit',
            serviceDescription: 'Professional hemming service'
          }
        ]
      }
    ],
    ordered_at: admin.firestore.FieldValue.serverTimestamp(),
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp()
  };

  // Add sample order and then delete it (just to create collection)
  const docRef = db.collection('orders').doc('sample_order');
  await docRef.set(sampleOrder);
  await docRef.delete(); // Delete sample order immediately
  
  console.log('✅ Orders Collection structure created');
}

// 3. Loyalty Progress Collection (matches loyalty_progress table)
async function setupLoyaltyProgress() {
  console.log('🎯 Setting up Loyalty Progress Collection...');
  
  // Create a sample loyalty progress structure (to be deleted after setup)
  const sampleLoyalty = {
    // Structure matches SQL loyalty_progress table
    user_id: 'sample_user_id', // Will be replaced with actual Firebase Auth UID
    completed_orders: 0, // 0-5, resets after free order
    lifetime_orders: 0, // Total orders ever placed
    total_free_orders_claimed: 0, // Number of free orders used
    last_free_order_date: null,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp()
  };

  // Add sample and delete to create collection structure
  const docRef = db.collection('loyaltyProgress').doc('sample_loyalty');
  await docRef.set(sampleLoyalty);
  await docRef.delete();
  
  console.log('✅ Loyalty Progress Collection structure created');
}

// 4. Service Requests Collection (matches service_requests table)
async function setupServiceRequests() {
  console.log('🛠️ Setting up Service Requests Collection...');
  
  // Create a sample service request structure (to be deleted after setup)
  const sampleServiceRequest = {
    // Structure matches SQL service_requests table
    request_text: 'I need hemming for my dress pants',
    service_type: 'alterations',
    user_selections: {
      item_type: 'pants',
      service_needed: 'hemming',
      measurements: {
        length: '32 inches'
      }
    },
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp()
  };

  // Add sample and delete to create collection structure
  const docRef = db.collection('serviceRequests').doc('sample_request');
  await docRef.set(sampleServiceRequest);
  await docRef.delete();
  
  console.log('✅ Service Requests Collection structure created');
}

// Run the schema setup
setupHouseOfTailorsSchema();

module.exports = { setupHouseOfTailorsSchema };