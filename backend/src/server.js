import { app } from './app.js';

const port = process.env.PORT ?? 3000;
app.listen(port, (err) => {
  if (err) throw err; // e.g. EADDRINUSE: crash instead of exiting 0 looking healthy
  console.log(`API listening on :${port}`);
});
