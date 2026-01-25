const mongoose = require('mongoose');
require('dotenv').config();

const fixDatabase = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const db = mongoose.connection.db;
        const collections = await db.listCollections().toArray();
        for (const collectionInfo of collections) {
            const collectionName = collectionInfo.name;
            const collection = db.collection(collectionName);
            const collectionIndexes = await collection.indexes();

            console.log(`Checking indexes for collection: ${collectionName}`);

            const indexesToDrop = ['phoneNumber_1'];
            for (const indexName of indexesToDrop) {
                const exists = collectionIndexes.some(idx => idx.name === indexName);
                if (exists) {
                    console.log(`Dropping index: ${indexName} from ${collectionName}`);
                    await collection.dropIndex(indexName);
                }
            }
        }

        console.log('Database indexes fixed successfully');
        process.exit(0);
    } catch (error) {
        console.error('Error fixing database:', error);
        process.exit(1);
    }
};

fixDatabase();
