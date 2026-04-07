const mongoose = require('mongoose');

const fixDB = async () => {
    try {
        const uri = 'mongodb+srv://lms:lms123@cluster0.siobua7.mongodb.net/ricemill?retryWrites=true&w=majority&appName=Cluster0';
        await mongoose.connect(uri);
        console.log('Connected to MongoDB');

        const db = mongoose.connection.db;
        const collection = db.collection('companies');
        
        // 1. Unset registrationNumber where it is null
        const result = await collection.updateMany(
            { registrationNumber: null },
            { $unset: { registrationNumber: "" } }
        );
        console.log(`Updated ${result.modifiedCount} documents (removed null registrationNumber)`);

        // 2. Drop the existing index
        try {
            await collection.dropIndex('registrationNumber_1');
            console.log('Dropped index registrationNumber_1');
        } catch (e) {
            console.log('Index registrationNumber_1 not found or already dropped');
        }

        // 3. Recreate the index as unique AND sparse
        await collection.createIndex(
            { registrationNumber: 1 },
            { unique: true, sparse: true, background: true }
        );
        console.log('Created sparse unique index for registrationNumber');

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

fixDB();
