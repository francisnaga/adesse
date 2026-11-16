// Build script to generate config.js from Vercel / CI Environment Variables
// and prepare the web bundle for Capacitor Android & iOS builds
const fs = require('fs');
const path = require('path');

const supabaseUrl = process.env.SUPABASE_URL || 
                    process.env.NEXT_PUBLIC_SUPABASE_URL || 
                    process.env.VITE_SUPABASE_URL || 
                    'https://xbgolunipyuhyparskmu.supabase.co';

const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 
                        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 
                        process.env.VITE_SUPABASE_ANON_KEY || 
                        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhiZ29sdW5pcHl1aHlwYXJza211Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ4MjI1NzYsImV4cCI6MjExMDM5ODU3Nn0.1jrk7apaQw-ds4FNgZZhmvaKgQZoK69HIi1c6WTTz8o';

const supportEmail = process.env.SUPPORT_EMAIL || 'efobifrancis53@gmail.com';
const appName = process.env.APP_NAME || 'Adesse';

const configContent = `// Auto-generated configuration for Adesse
// Generated at build time from environment variables
window.ADESSE_CONFIG = {
  supabaseUrl: ${JSON.stringify(supabaseUrl)},
  supabaseAnonKey: ${JSON.stringify(supabaseAnonKey)},
  supportEmail: ${JSON.stringify(supportEmail)},
  appName: ${JSON.stringify(appName)}
};
`;

fs.writeFileSync('config.js', configContent);
console.log('✓ Successfully generated root config.js');

// Ensure www folder exists for Capacitor builds
const wwwDir = path.join(__dirname, 'www');
if (!fs.existsSync(wwwDir)) {
  fs.mkdirSync(wwwDir, { recursive: true });
}

// Files to copy to www
const filesToCopy = [
  'index.html',
  'config.js',
  'manifest.webmanifest',
  'sw.js',
  'privacy.html',
  'delete-account.html',
  'icon-192.png',
  'icon-512.png',
  'apple-touch-icon.png',
  'favicon.png',
  'icon.svg'
];

for (const file of filesToCopy) {
  if (fs.existsSync(file)) {
    fs.copyFileSync(file, path.join(wwwDir, file));
  }
}
console.log('✓ Successfully synced web assets to www/ for Capacitor');
