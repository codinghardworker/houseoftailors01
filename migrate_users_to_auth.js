// Migration Script: Add Firestore users to Firebase Auth
// This script creates Firebase Auth accounts for users that exist only in Firestore

const admin = require('firebase-admin');

// Initialize Firebase Admin (use existing credentials)
const serviceAccount = require('./houseoftailors1-786c5-firebase-adminsdk-fbsvc-ce745cd85c.json');

// Only initialize if not already initialized
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const auth = admin.auth();
const db = admin.firestore();

async function migrateUsersToAuth() {
  console.log('🔄 Starting user migration to Firebase Auth...');

  try {
    // Get all users from Firestore
    const usersSnapshot = await db.collection('users').get();
    console.log(`Found ${usersSnapshot.docs.length} users in Firestore`);

    let migrated = 0;
    let skipped = 0;
    let errors = 0;

    for (const doc of usersSnapshot.docs) {
      const userData = doc.data();
      const userId = doc.id;
      const email = userData.email || userData.customerEmail;
      const fullName = userData.fullName || userData.customerName;

      if (!email) {
        console.log(`⚠️ Skipping user ${userId} - no email found`);
        skipped++;
        continue;
      }

      try {
        // Check if user already exists in Firebase Auth
        let authUser = null;
        try {
          authUser = await auth.getUserByEmail(email);
          console.log(`✅ User ${email} already exists in Firebase Auth`);
          skipped++;
          continue;
        } catch (e) {
          // User doesn't exist in Auth, we'll create them
        }

        // Create user in Firebase Auth
        const createRequest = {
          uid: userId, // Use Firestore document ID as Auth UID
          email: email,
          emailVerified: true, // Mark as verified since they're existing users
          displayName: fullName || 'User',
          // Set a temporary password - user will need to reset it
          password: 'TempPassword123!',
        };

        authUser = await auth.createUser(createRequest);
        console.log(`✅ Created Firebase Auth user for ${email} with UID: ${authUser.uid}`);
        migrated++;

        // Optional: Send password reset email immediately after creation
        try {
          await auth.generatePasswordResetLink(email);
          console.log(`📧 Password reset link generated for ${email}`);
        } catch (resetError) {
          console.log(`⚠️ Could not generate reset link for ${email}: ${resetError.message}`);
        }

      } catch (error) {
        console.error(`❌ Error migrating user ${email}:`, error.message);
        errors++;
      }
    }

    console.log('\n=== MIGRATION SUMMARY ===');
    console.log(`✅ Migrated: ${migrated} users`);
    console.log(`⏭️ Skipped: ${skipped} users (already exist)`);
    console.log(`❌ Errors: ${errors} users`);
    console.log('==========================');

    if (migrated > 0) {
      console.log('\n📧 IMPORTANT: All migrated users have been given a temporary password.');
      console.log('They will need to use the "Forgot Password" feature to set a new password.');
      console.log('Consider sending them an email notification about this.');
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
  }
}

// Helper function to migrate a specific user
async function migrateSingleUser(email) {
  console.log(`🔄 Migrating single user: ${email}`);

  try {
    // Check if user exists in Firestore
    const userQuery = await db.collection('users').where('email', '==', email).limit(1).get();
    
    if (userQuery.empty) {
      console.log(`❌ User ${email} not found in Firestore`);
      return false;
    }

    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();
    const userId = userDoc.id;
    const fullName = userData.fullName || userData.customerName;

    // Check if already exists in Auth
    try {
      await auth.getUserByEmail(email);
      console.log(`✅ User ${email} already exists in Firebase Auth`);
      return true;
    } catch (e) {
      // User doesn't exist, proceed with creation
    }

    // Create in Firebase Auth
    const authUser = await auth.createUser({
      uid: userId,
      email: email,
      emailVerified: true,
      displayName: fullName || 'User',
      password: 'TempPassword123!',
    });

    console.log(`✅ Successfully migrated ${email} to Firebase Auth`);
    
    // Generate password reset link
    try {
      await auth.generatePasswordResetLink(email);
      console.log(`📧 Password reset link generated for ${email}`);
    } catch (resetError) {
      console.log(`⚠️ Could not generate reset link: ${resetError.message}`);
    }

    return true;

  } catch (error) {
    console.error(`❌ Error migrating ${email}:`, error.message);
    return false;
  }
}

// Run migration
if (require.main === module) {
  // Check if specific email provided as argument
  const specificEmail = process.argv[2];
  
  if (specificEmail) {
    migrateSingleUser(specificEmail);
  } else {
    migrateUsersToAuth();
  }
}

module.exports = { migrateUsersToAuth, migrateSingleUser };