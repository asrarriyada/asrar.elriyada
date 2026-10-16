const https = require('https');

function fetchNewsFromFirebase(newsId) {
  return new Promise((resolve) => {
    const url = `https://firestore.googleapis.com/v1/projects/asrar-elriyada-8ee46/databases/(default)/documents/news/${newsId}`;
    
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed && parsed.fields) {
            const fields = parsed.fields;
            
            // استخراج العنوان والوصف بكل الأشكال الممكنة
            let title = "أسرار الرياضة";
            if (fields.title && fields.title.stringValue) title = fields.title.stringValue;

            let description = "تابع أحدث الأخبار الرياضية الحصرية على موقع أسرار الرياضة.";
            if (fields.content && fields.content.stringValue) {
              description = fields.content.stringValue.substring(0, 150) + '...';
            } else if (fields.description && fields.description.stringValue) {
              description = fields.description.stringValue.substring(0, 150) + '...';
            }

            // استخراج الصورة بكل الأشكال الممكنة (imageUrl أو image أو img)
            let rawImage = "";
            const possibleKeys = ['imageUrl', 'image', 'img', 'photo', 'newsImage'];
            for (const key of possibleKeys) {
              if (fields[key] && fields[key].stringValue) {
                rawImage = fields[key].stringValue;
                break;
              }
            }

            // التأكد أن الرابط صالح ويبدأ بـ http
            let validImage = (rawImage && rawImage.startsWith('http') && !rawImage.startsWith('data:image')) 
              ? rawImage 
              : "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEjd0ZC-04Q3NpiEdkyGRSZ9kszkav85Fnl8axL2refTb3mgC8QknhprJBxXboMIhuhZFnVM-k0ue8UiLyd5Z8GYCwal98yTQ9pdJCAiNGe9aOKIg3019hQ6a6D31L8fUuI1xuIx1S8ShTsll25ibz0z905_fGAQkQrWyPvrDlojXHqUsZLG4naEbuCVU7o/s800/382817_0.jpg"; // صورة الخبر الافتراضية بتاعتك كاحتياطي

            resolve({ title, image: validImage, description });
          } else {
            resolve(null);
          }
        } catch (e) {
          resolve(null);
        }
      });
    }).on('error', () => {
      resolve(null);
    });
  });
}

module.exports = async (req, res) => {
  const { id } = req.query;
  const userAgent = req.headers['user-agent'] || '';

  let title = "أسرار الرياضة";
  let description = "تابع أحدث الأخبار الرياضية الحصرية على موقع أسرار الرياضة.";
  let imageUrl = "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEjd0ZC-04Q3NpiEdkyGRSZ9kszkav85Fnl8axL2refTb3mgC8QknhprJBxXboMIhuhZFnVM-k0ue8UiLyd5Z8GYCwal98yTQ9pdJCAiNGe9aOKIg3019hQ6a6D31L8fUuI1xuIx1S8ShTsll25ibz0z905_fGAQkQrWyPvrDlojXHqUsZLG4naEbuCVU7o/s800/382817_0.jpg";

  if (id) {
    const newsData = await fetchNewsFromFirebase(id);
    if (newsData) {
      title = newsData.title;
      imageUrl = newsData.image;
      description = newsData.description;
    }
  }

  const targetUrl = `https://asrarriyada.github.io/asrar.elriyada/?id=${id || ''}`;
  const isBot = /facebookexternalhit|Facebot|Twitterbot|WhatsApp|TelegramBot|LinkedInBot/i.test(userAgent);

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  
  if (!isBot) {
    res.writeHead(302, { Location: targetUrl });
    return res.end();
  }

  return res.status(200).send(`<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>${title}</title>
    <meta property="og:site_name" content="أسرار الرياضة">
    <meta property="og:title" content="${title}">
    <meta property="og:description" content="${description}">
    <meta property="og:image" content="${imageUrl}">
    <meta property="og:image:secure_url" content="${imageUrl}">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:url" content="https://asrar-share.vercel.app/api?id=${id || ''}">
    <meta property="og:type" content="article">
</head>
<body>
    <h1>${title}</h1>
    <p>${description}</p>
</body>
</html>`);
};