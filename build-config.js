// Build script to generate config.js from Vercel / CI Environment Variables
// and prepare the web bundle for Capacitor Android, iOS, and Vercel public deployments
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
const googleClientId = process.env.GOOGLE_CLIENT_ID || '483287071794-ovfunsnva28icu5u9bmfqt0oa7acbnsq.apps.googleusercontent.com';

const configContent = `// Auto-generated configuration for Adesse
// Generated at build time from environment variables
window.ADESSE_CONFIG = {
  supabaseUrl: ${JSON.stringify(supabaseUrl)},
  supabaseAnonKey: ${JSON.stringify(supabaseAnonKey)},
  supportEmail: ${JSON.stringify(supportEmail)},
  appName: ${JSON.stringify(appName)},
  googleClientId: ${JSON.stringify(googleClientId)}
};
`;

// Write to root
fs.writeFileSync(path.join(__dirname, 'config.js'), configContent);
console.log('✓ Successfully generated root config.js');

// Files to copy to target directories
const filesToCopy = [
  'index.html',
  'config.js',
  'manifest.webmanifest',
  'sw.js',
  'privacy.html',
  'terms.html',
  'delete-account.html',
  'icon-192.png',
  'icon-512.png',
  'apple-touch-icon.png',
  'favicon.png',
  'icon.svg'
];

function syncDirectory(targetDirName) {
  const targetDir = path.join(__dirname, targetDirName);
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }
  for (const file of filesToCopy) {
    const src = path.join(__dirname, file);
    if (fs.existsSync(src)) {
      fs.copyFileSync(src, path.join(targetDir, file));
    }
  }
  console.log(`✓ Successfully synced web assets to ${targetDirName}/`);
}

// Sync to www (Capacitor) and public (Vercel)
syncDirectory('www');
syncDirectory('public');
