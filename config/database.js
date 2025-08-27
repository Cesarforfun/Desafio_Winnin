import mongoose from "mongoose";

export function dataBaseConnection() {
	// Linha de depuração
  console.log('Tentando conectar com a URI:', process.env.MONGO_URI);
  const params = {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  };
  try {
    mongoose.set("strictQuery", true);
    mongoose.connect(process.env.DB_URI, params);
    .then(() =>console.log("MongoDB connected sucessfully");
  } catch (error) {
    console.log("MongoDB Connection Failed", error);
  }
}
