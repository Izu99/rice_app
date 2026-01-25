const mongoose = require('mongoose')
require('dotenv').config()

async function fixDatabase () {
  try {
    console.log('🔄 Connecting to database to fix indexes...')
    await mongoose.connect(process.env.MONGODB_URI)
    console.log('✅ Connected to MongoDB')

    const collections = ['users', 'customers']
    const keepIndexes = ['_id_', 'email_1', 'phone_1', 'companyId_1', 'role_1', 'clientId_1', 'phone_1_companyId_1']

    for (const collectionName of collections) {
      console.log(`\n🔍 Checking collection: ${collectionName}`)
      const collection = mongoose.connection.db.collection(collectionName)
      const indexes = await collection.indexes()

      for (const idx of indexes) {
        if (!keepIndexes.includes(idx.name) && idx.unique) {
          console.log(`🗑️ Found unknown unique index "${idx.name}". Dropping it...`)
          try {
            await collection.dropIndex(idx.name)
            console.log(`✅ Index "${idx.name}" dropped successfully.`)
          } catch (e) {
            console.log(`⚠️ Could not drop index "${idx.name}": ${e.message}`)
          }
        }
      }
    }

    console.log('\n🎉 Database fix completed!')
    process.exit(0)
  } catch (error) {
    console.error('\n❌ Error fixing database:', error)
    process.exit(1)
  }
}

fixDatabase()
