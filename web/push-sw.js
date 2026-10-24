// push-sw.js — recebe as notificações push do Café Conecta e abre o app ao tocar.
// Registrado com escopo próprio (/push/) para não interferir no service worker do Flutter.
self.addEventListener('push', (evento) => {
  let dados = {};
  try { dados = evento.data ? evento.data.json() : {}; } catch (_) { dados = { corpo: evento.data && evento.data.text() }; }
  const titulo = dados.titulo || 'Café Conecta';
  evento.waitUntil(self.registration.showNotification(titulo, {
    body: dados.corpo || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: { url: dados.url || '/' },
    lang: 'pt-BR',
  }));
});

self.addEventListener('notificationclick', (evento) => {
  evento.notification.close();
  const destino = new URL((evento.notification.data && evento.notification.data.url) || '/', self.location.origin).href;
  evento.waitUntil((async () => {
    const abertas = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const c of abertas) {
      if (new URL(c.url).origin === self.location.origin && 'focus' in c) return c.focus();
    }
    return clients.openWindow(destino);
  })());
});
