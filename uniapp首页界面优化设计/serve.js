const http=require('http'),fs=require('fs'),path=require('path');
const R=path.join(__dirname,'app');
const M={'.html':'text/html;charset=utf-8','.css':'text/css','.js':'application/javascript'};
http.createServer((q,r)=>{
  let p=decodeURIComponent(q.url.split('?')[0]);
  if(p==='/')p='/index.html';
  fs.readFile(path.join(R,p),(e,d)=>{
    if(e){r.writeHead(404);r.end();return}
    r.writeHead(200,{'Content-Type':M[path.extname(p)]||'application/octet-stream','Cache-Control':'no-cache'});
    r.end(d);
  });
}).listen(8767,'127.0.0.1',()=>console.log('OK on 8767'));
