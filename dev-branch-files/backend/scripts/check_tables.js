const https = require('https');

const url = 'https://vasmnfhxuocseejomvhd.supabase.co/rest/v1/';
const apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZhc21uZmh4dW9jc2Vlam9tdmhkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NDcxMDEyMiwiZXhwIjoyMTAwMjg2MTIyfQ.xU3-_LXwokHr6HcbYsqG7Cmik_c9Mxy3kOaRFza0BT4';

const options = {
  headers: {
    'apikey': apiKey,
    'Authorization': `Bearer ${apiKey}`
  }
};

https.get(url, options, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const json = JSON.parse(data);
      if (json.definitions) {
        console.log('Tables found in Faculty Supabase REST API:');
        console.log(Object.keys(json.definitions));
      } else {
        console.log('Response:', data);
      }
    } catch(e) {
      console.log('Raw response:', data);
    }
  });
}).on('error', err => console.error(err));
