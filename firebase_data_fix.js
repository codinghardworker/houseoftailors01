// Firebase Data Fix - Create correct shopConfig data structure
// This script creates the shopConfig data that matches ShopConfigService expectations

const admin = require('firebase-admin');

// Initialize Firebase Admin (use existing credentials)
const serviceAccount = require('./houseoftailors1-786c5-firebase-adminsdk-fbsvc-ce745cd85c.json');

// Only initialize if not already initialized
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function fixFirebaseData() {
  console.log('🔧 Fixing Firebase shopConfig data structure...');

  try {
    // Clear existing shopConfig collection
    const existingDocs = await db.collection('shopConfig').get();
    const batch = db.batch();
    
    existingDocs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log('✅ Cleared existing shopConfig data');

    // Add correct shopConfig data matching ShopConfigService structure
    await addCorrectShopConfig();
    
    console.log('✅ Firebase data fix complete!');
  } catch (error) {
    console.error('❌ Data fix failed:', error);
  }
}

async function addCorrectShopConfig() {
  console.log('📋 Adding correct shopConfig structure...');
  
  const shopConfigs = [
    // Shop Information
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

    // Delivery Options  
    {
      config_key: 'delivery_options',
      config_value: {
        pickup_charge_pence: 1000, // £10.00
        post_delivery_charge_pence: 0, // Free post delivery
        free_delivery_threshold_pence: 5000, // £50.00
        currency: "GBP",
        available_methods: ["pickup", "post"]
      },
      description: 'Available delivery methods and charges in pence',
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    },

    // Pickup Slots
    {
      config_key: 'pickup_slots',
      config_value: {
        monday: { 
          available_slots: [
            "10:00 AM - 11:00 AM", 
            "11:00 AM - 12:00 PM", 
            "12:00 PM - 1:00 PM", 
            "2:00 PM - 3:00 PM", 
            "3:00 PM - 4:00 PM", 
            "4:00 PM - 5:00 PM"
          ] 
        },
        tuesday: { 
          available_slots: [
            "10:00 AM - 11:00 AM", 
            "11:00 AM - 12:00 PM", 
            "12:00 PM - 1:00 PM", 
            "2:00 PM - 3:00 PM", 
            "3:00 PM - 4:00 PM", 
            "4:00 PM - 5:00 PM"
          ] 
        },
        wednesday: { 
          available_slots: [
            "10:00 AM - 11:00 AM", 
            "11:00 AM - 12:00 PM", 
            "12:00 PM - 1:00 PM", 
            "2:00 PM - 3:00 PM", 
            "3:00 PM - 4:00 PM", 
            "4:00 PM - 5:00 PM"
          ] 
        },
        thursday: { 
          available_slots: [
            "10:00 AM - 11:00 AM", 
            "11:00 AM - 12:00 PM", 
            "12:00 PM - 1:00 PM", 
            "2:00 PM - 3:00 PM", 
            "3:00 PM - 4:00 PM", 
            "4:00 PM - 5:00 PM"
          ] 
        },
        friday: { 
          available_slots: [
            "10:00 AM - 11:00 AM", 
            "11:00 AM - 12:00 PM", 
            "12:00 PM - 1:00 PM", 
            "2:00 PM - 3:00 PM", 
            "3:00 PM - 4:00 PM", 
            "4:00 PM - 5:00 PM"
          ] 
        },
        saturday: { 
          available_slots: [
            "10:00 AM - 11:00 AM", 
            "11:00 AM - 12:00 PM", 
            "12:00 PM - 1:00 PM", 
            "2:00 PM - 3:00 PM"
          ] 
        },
        sunday: { 
          available_slots: [] 
        }
      },
      description: 'Available pickup time slots by day',
      is_active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    },

    // Available Locations
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
      description: 'Available cities and towns for service',
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
  console.log('✅ Correct shopConfig data structure added');
}

// Run the fix
fixFirebaseData();

module.exports = { fixFirebaseData };