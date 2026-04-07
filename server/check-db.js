const mongoose = require('mongoose');

const checkDB = async () => {
    try {
        const uri = 'mongodb+srv://lms:lms123@cluster0.siobua7.mongodb.net/ricemill?retryWrites=true&w=majority&appName=Cluster0';
        await mongoose.connect(uri);
        console.log('Connected to MongoDB');

        const db = mongoose.connection.db;
        const collection = db.collection('companies');
        
        const companies = await collection.find({}).toArray();
        console.log('Total companies:', companies.length);
        
        companies.forEach(c => {
            console.log(`ID: ${c._id}, Name: ${c.name}, Reg: ${JSON.stringify(c.registrationNumber)}`);
        });

        const indexes = await collection.indexes();
        console.log('Current Indexes:', JSON.stringify(indexes, null, 2));

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

checkDB();
