import './style.css';

// Cada módulo describe sus campos y columnas. La interfaz y las peticiones son compartidas.
const ENTIDADES = [
  {
    key: 'clientes', titulo: 'Clientes', singular: 'cliente', icon: 'users', tecnologia: 'Python · Flask',
    etiqueta: 'DIRECTORIO', descripcion: 'Las personas detrás de cada operación.', tabla: 'Directorio de clientes',
    campos: [
      { name: 'nombre', label: 'Nombre completo', type: 'text', max: 100, placeholder: 'Ej. Ana Torres', autocomplete: 'name' },
      { name: 'email', label: 'Correo electrónico', type: 'email', max: 150, placeholder: 'ana@ejemplo.com', autocomplete: 'email' },
      { name: 'dni', label: 'DNI', type: 'text', max: 20, placeholder: 'Ej. 30111222', optional: true },
    ],
    columnas: [['id', 'ID', 'id'], ['nombre', 'Nombre', 'person'], ['email', 'Correo electrónico'], ['dni', 'DNI', 'mono']],
  },
  {
    key: 'pagos', titulo: 'Pagos', singular: 'pago', icon: 'wallet', tecnologia: 'Node.js · Express',
    etiqueta: 'MOVIMIENTOS', descripcion: 'Cada pago, con sus importes y su medio de origen.', tabla: 'Registro de pagos',
    nota: 'La API calcula el importe en USD al guardar. Si la cotización no está disponible, el pago puede guardarse sin esa conversión.',
    campos: [
      { name: 'monto_ars', label: 'Importe en ARS', type: 'number', money: true, placeholder: '0,00' },
      { name: 'medio_pago', label: 'Medio de pago', type: 'text', max: 30, placeholder: 'Ej. transferencia', suggestions: ['transferencia', 'tarjeta_debito', 'tarjeta_credito', 'efectivo'] },
    ],
    columnas: [['id', 'ID', 'id'], ['monto_ars', 'Importe ARS', 'ARS'], ['monto_usd', 'Importe USD', 'USD'], ['medio_pago', 'Medio de pago', 'tag'], ['fecha', 'Fecha', 'dateTime']],
  },
  {
    key: 'facturas', titulo: 'Facturas', singular: 'factura', icon: 'file', tecnologia: 'Java · Spring Boot',
    etiqueta: 'COMPROBANTES', descripcion: 'La facturación de tu operación, ordenada y accesible.', tabla: 'Registro de facturas',
    campos: [
      { name: 'numero', label: 'Número de factura', type: 'text', max: 30, placeholder: 'Ej. A-0003' },
      { name: 'monto', label: 'Importe en ARS', type: 'number', money: true, placeholder: '0,00' },
      { name: 'clienteId', label: 'ID del cliente', type: 'number', integer: true, placeholder: 'Ej. 1' },
      { name: 'fechaEmision', label: 'Fecha de emisión', type: 'date' },
    ],
    columnas: [['id', 'ID', 'id'], ['numero', 'Número', 'strong'], ['monto', 'Importe ARS', 'ARS'], ['clienteId', 'ID del cliente', 'id'], ['fechaEmision', 'Emisión', 'date']],
  },
  {
    key: 'transacciones', titulo: 'Transacciones', singular: 'transacción', icon: 'arrows', tecnologia: 'Go · net/http',
    etiqueta: 'ACTIVIDAD', descripcion: 'Seguí los movimientos y su información de origen.', tabla: 'Registro de transacciones',
    nota: 'El país se consulta a partir de la IP al guardar. Si el proveedor externo no responde o limita las consultas, aparecerá como no disponible.',
    campos: [
      { name: 'origen_ip', label: 'IP de origen', type: 'text', max: 45, placeholder: 'Ej. 8.8.8.8' },
      { name: 'monto', label: 'Importe en ARS', type: 'number', money: true, placeholder: '0,00' },
      { name: 'tipo', label: 'Tipo de transacción', type: 'text', max: 30, placeholder: 'Ej. compra', suggestions: ['compra', 'retiro', 'transferencia'] },
    ],
    columnas: [['id', 'ID', 'id'], ['origen_ip', 'IP de origen', 'mono'], ['pais', 'País', 'country'], ['monto', 'Importe ARS', 'ARS'], ['tipo', 'Tipo', 'tag']],
  },
  {
    key: 'tarjetas', titulo: 'Tarjetas', singular: 'tarjeta', icon: 'card', tecnologia: 'C# · ASP.NET Core',
    etiqueta: 'MEDIOS DE PAGO', descripcion: 'Titulares, tipos y límites, en un mismo lugar.', tabla: 'Directorio de tarjetas',
    campos: [
      { name: 'alias', label: 'Alias de la tarjeta', type: 'text', max: 50, placeholder: 'Ej. Visa Gold' },
      { name: 'titular', label: 'Nombre del titular', type: 'text', max: 100, placeholder: 'Ej. Ana Torres' },
      { name: 'tipo', label: 'Tipo de tarjeta', type: 'select', options: [['credito', 'Crédito'], ['debito', 'Débito']] },
      { name: 'limite', label: 'Límite en ARS', type: 'number', money: true, placeholder: '0,00' },
    ],
    columnas: [['id', 'ID', 'id'], ['alias', 'Tarjeta', 'strong'], ['titular', 'Titular'], ['tipo', 'Tipo', 'tag'], ['limite', 'Límite ARS', 'ARS']],
  },
];

// SVG locales: no dependemos de fuentes, imágenes ni librerías de iconos externas.
const paths = {
  users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2m20 0v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/><circle cx="9" cy="7" r="4"/>',
  wallet: '<path d="M20 8V5a2 2 0 0 0-2-2H5a3 3 0 0 0 0 6h15v12H5a3 3 0 0 1-3-3V6m18 6h-5v5h5"/><path d="M16 14.5h.01"/>',
  file: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8zM14 2v6h6M8 13h8M8 17h5"/>',
  arrows: '<path d="M4 7h16m-4-4 4 4-4 4M20 17H4m4-4-4 4 4 4"/>',
  card: '<rect x="2" y="4" width="20" height="16" rx="3"/><path d="M2 10h20M6 15h4"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  search: '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 4 4"/>',
  refresh: '<path d="M20 7v5h-5M4 17v-5h5"/><path d="M6.1 6a8 8 0 0 1 13.5 5M4.4 13A8 8 0 0 0 18 18"/>',
  edit: '<path d="m16 3 5 5-12 12H4v-5zM13 6l5 5"/>',
  trash: '<path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7M14 10v7"/>',
  close: '<path d="m6 6 12 12M6 18 18 6"/>',
  check: '<path d="m5 12 4 4L19 6"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7h.01"/>',
  arrow: '<path d="M5 12h14m-5-5 5 5-5 5"/>',
  layers: '<path d="m12 3 10 5-10 5L2 8zM2 12l10 5 10-5M2 16l10 5 10-5"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
};
const icon = (name) => `<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.65" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name] || paths.file}</svg>`;
const $ = (selector) => document.querySelector(selector);
const estados = Object.fromEntries(ENTIDADES.map(e => [e.key, { rows: [], loaded: false, loading: false, error: '', updated: null, query: '' }]));
let activa = ENTIDADES[0];
let edicion = null;
let eliminacion = null;
let guardando = false;
let borrando = false;
let toastTimer;

function node(tag, className, text) {
  const element = document.createElement(tag);
  if (className) element.className = className;
  if (text !== undefined) element.textContent = text;
  return element;
}

const app = $('#app');
app.innerHTML = `
  <a class="skip-link" href="#contenido">Saltar al contenido</a>
  <aside class="sidebar">
    <a class="brand" href="#clientes" aria-label="Fintech Nova, inicio"><span class="brand-mark">N<span></span></span><span>nova<span class="brand-sub">FINTECH</span></span></a>
    <div class="workspace"><span class="workspace-icon">${icon('layers')}</span><div><strong>Panel de operaciones</strong><span>Fintech Nova</span></div></div>
    <p class="nav-label">ESPACIO DE TRABAJO</p>
    <nav class="navigation" aria-label="Módulos de operaciones">
      ${ENTIDADES.map(e => `<a href="#${e.key}" data-nav="${e.key}" class="nav-item">${icon(e.icon)}<span>${e.titulo}</span><span class="nav-count" data-count="${e.key}">—</span></a>`).join('')}
    </nav>
    <div class="sidebar-bottom"><div class="architecture-mark">${icon('layers')}<span>Una entrada. Cinco servicios.</span></div><p>Nginx <span>→</span> APIs <span>→</span> MariaDB</p><div class="team"><span class="team-avatar">10</span><div><strong>Grupo 10</strong><span>Laboratorio DevOps · 2026</span></div></div></div>
  </aside>
  <div class="main-shell">
    <header class="topbar"><div class="breadcrumb"><span>Operaciones</span><span class="slash">/</span><strong id="breadcrumb-title">Clientes</strong></div><span class="environment"><span class="small-dot"></span>Entorno académico</span></header>
    <main id="contenido" tabindex="-1">
      <section class="page-heading"><div><p class="eyebrow" id="eyebrow"></p><h1 id="page-title"></h1><p id="page-description" class="description"></p></div><button class="button primary" id="new-record">${icon('plus')}<span></span></button></section>
      <section class="summary-grid" aria-label="Resumen del módulo">
        <div class="summary-card"><span class="summary-label">REGISTROS TOTALES</span><div class="summary-value" id="total-count">—</div><span class="summary-detail" id="total-detail">Pendiente de consulta</span><span class="summary-icon" id="entity-icon"></span></div>
        <div class="summary-card"><span class="summary-label">SERVICIO DEL MÓDULO</span><div class="service-name" id="service-name"></div><span class="summary-detail" id="technology"></span><span class="summary-icon">${icon('layers')}</span></div>
        <div class="summary-card"><span class="summary-label">ÚLTIMA CONSULTA CORRECTA</span><div class="time-value" id="last-update">—</div><span class="summary-detail status-detail" id="service-status">Sin consultar</span><span class="summary-icon">${icon('clock')}</span></div>
      </section>
      <section class="data-panel" aria-labelledby="table-title">
        <div class="panel-toolbar"><div><h2 id="table-title"></h2><p class="panel-subtitle">Consultá, agregá y administrá tus registros.</p></div><div class="table-controls"><div class="search-box">${icon('search')}<input id="search" type="search" placeholder="Buscar en este módulo…" aria-label="Buscar registros" autocomplete="off" /></div><button class="button icon-button" id="refresh" title="Actualizar registros" aria-label="Actualizar registros">${icon('refresh')}</button></div></div>
        <div id="load-error" class="notice error" role="alert" hidden></div>
        <div id="data-region" aria-busy="false"><div class="table-scroll" role="region" aria-label="Tabla de registros; desplazable en pantallas pequeñas" tabindex="0"><table><caption class="sr-only" id="table-caption"></caption><thead id="table-head"></thead><tbody id="table-body"></tbody></table></div><div id="empty-state" class="empty-state" hidden></div></div>
        <div class="table-footer"><span id="results-summary" aria-live="polite"></span><span class="endpoint" id="endpoint"></span></div>
      </section>
      <aside class="module-note" id="module-note" hidden>${icon('info')}<p></p></aside>
      <footer class="page-footer"><span>Fintech Nova <span class="footer-divider">/</span> Operaciones simples, información clara.</span><span>Proyecto académico · Usá datos ficticios</span></footer>
    </main>
  </div>
  <dialog id="record-dialog" aria-labelledby="record-title" aria-describedby="record-description">
    <form id="record-form"><div class="dialog-header"><span class="dialog-symbol" id="dialog-symbol"></span><button type="button" class="button icon-button plain" data-close="record" aria-label="Cerrar formulario">${icon('close')}</button></div><p class="eyebrow">GESTIÓN DE REGISTROS</p><h2 id="record-title"></h2><p class="dialog-description" id="record-description"></p><div class="form-grid" id="form-fields"></div><p id="form-note" class="form-note" hidden></p><div class="notice error" id="form-error" role="alert" hidden></div><div class="dialog-actions"><button type="button" class="button secondary" data-close="record">Cancelar</button><button type="submit" class="button primary" id="save-record">Guardar</button></div></form>
  </dialog>
  <dialog id="delete-dialog" aria-labelledby="delete-title" aria-describedby="delete-description"><div class="delete-content"><span class="dialog-symbol danger-symbol">${icon('trash')}</span><h2 id="delete-title">¿Eliminar este registro?</h2><p id="delete-description" class="dialog-description"></p><div class="notice error" id="delete-error" role="alert" hidden></div><div class="dialog-actions"><button type="button" class="button secondary" id="cancel-delete" autofocus>Conservar registro</button><button type="button" class="button danger" id="confirm-delete">Eliminar registro</button></div></div></dialog>
  <div class="toast" id="toast" role="status" aria-live="polite" hidden></div>
`;

// Las URLs relativas conservan a Nginx como única puerta de entrada.
// No se incluyen IPs de contenedores, puertos internos ni credenciales en el navegador.
async function request(key, { method = 'GET', id, body } = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 20000);
  try {
    const response = await fetch(`/api/${key}${id == null ? '' : `/${encodeURIComponent(id)}`}`, {
      method, signal: controller.signal, cache: 'no-store',
      headers: { Accept: 'application/json', ...(body ? { 'Content-Type': 'application/json' } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    const text = response.status === 204 ? '' : await response.text();
    let data;
    try { data = text ? JSON.parse(text) : null; } catch { data = null; }
    if (!response.ok) {
      const detail = typeof data?.error === 'string' ? data.error : '';
      const message = response.status === 404 ? 'El registro no existe o ya fue eliminado.'
        : response.status >= 500 ? 'El servicio no pudo completar la solicitud. Revisá los logs de la API y la conexión con la base.'
        : detail.slice(0, 180) || 'El servicio rechazó la solicitud. Revisá los datos ingresados.';
      throw new Error(`${message} (HTTP ${response.status})`);
    }
    if (method === 'GET' && !Array.isArray(data)) throw new Error('La API no devolvió una lista válida. Revisá la ruta de Nginx.');
    return data;
  } catch (error) {
    if (error.name === 'AbortError' || error instanceof TypeError) {
      throw new Error(method === 'GET'
        ? 'No pudimos consultar el servicio. Comprobá que el stack esté encendido y volvé a actualizar.'
        : 'No pudimos confirmar la operación. Cerrá el formulario y actualizá la lista antes de volver a intentarlo: el servidor podría haberla aplicado.');
    }
    throw error;
  } finally { clearTimeout(timer); }
}

function notify(message, warning = false) {
  clearTimeout(toastTimer);
  const toast = $('#toast');
  toast.replaceChildren();
  const symbol = node('span');
  symbol.innerHTML = icon(warning ? 'info' : 'check');
  toast.append(symbol, node('span', '', message));
  toast.classList.toggle('toast-warning', warning);
  toast.hidden = false;
  toastTimer = setTimeout(() => { toast.hidden = true; }, warning ? 10000 : 5500);
}

function mensaje(element, text) {
  element.textContent = text;
  element.hidden = !text;
}

function seleccionar() {
  const key = location.hash.slice(1);
  activa = ENTIDADES.find(e => e.key === key) || ENTIDADES[0];
  for (const link of document.querySelectorAll('[data-nav]')) {
    if (link.dataset.nav === activa.key) link.setAttribute('aria-current', 'page');
    else link.removeAttribute('aria-current');
  }
  document.title = `${activa.titulo} · Fintech Nova`;
  $('#breadcrumb-title').textContent = activa.titulo;
  $('#eyebrow').textContent = activa.etiqueta;
  $('#page-title').textContent = activa.titulo;
  $('#page-description').textContent = activa.descripcion;
  $('#new-record span').textContent = `${['facturas', 'transacciones', 'tarjetas'].includes(activa.key) ? 'Nueva' : 'Nuevo'} ${activa.singular}`;
  $('#service-name').textContent = `api-${activa.key}`;
  $('#technology').textContent = activa.tecnologia;
  $('#entity-icon').innerHTML = icon(activa.icon);
  $('#table-title').textContent = activa.tabla;
  $('#table-caption').textContent = activa.tabla;
  $('#endpoint').textContent = `/api/${activa.key}`;
  $('#search').value = estados[activa.key].query;
  $('#module-note').hidden = !activa.nota;
  $('#module-note p').textContent = activa.nota || '';
  const head = node('tr');
  for (const [, label, type] of activa.columnas) {
    const th = node('th', ['ARS', 'USD'].includes(type) ? 'numeric' : '', label);
    th.scope = 'col';
    head.append(th);
  }
  const actions = node('th', 'actions-heading', 'Acciones');
  actions.scope = 'col';
  head.append(actions);
  $('#table-head').replaceChildren(head);
  renderDatos();
  if (!estados[activa.key].loaded && !estados[activa.key].loading) cargar(activa.key);
}

async function cargar(key) {
  const state = estados[key];
  if (state.loading) return;
  state.loading = true;
  state.error = '';
  if (activa.key === key) renderDatos();
  try {
    state.rows = await request(key);
    state.loaded = true;
    state.updated = new Date();
    $(`[data-count="${key}"]`).textContent = state.rows.length;
  } catch (error) { state.error = error.message; }
  finally {
    state.loading = false;
    if (activa.key === key) renderDatos();
  }
}

const money = Object.fromEntries(['ARS', 'USD'].map(currency => [currency, new Intl.NumberFormat('es-AR', { style: 'currency', currency, currencyDisplay: 'code' })]));
const words = { credito: 'Crédito', debito: 'Débito', tarjeta_debito: 'Tarjeta de débito', tarjeta_credito: 'Tarjeta de crédito', transferencia: 'Transferencia', efectivo: 'Efectivo', compra: 'Compra', retiro: 'Retiro' };
const normalizar = value => String(value ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();

function display(value, type) {
  if (value == null || value === '') return 'No disponible';
  if (type === 'ARS' || type === 'USD') return Number.isFinite(Number(value)) ? money[type].format(Number(value)) : 'No disponible';
  if (type === 'date' || type === 'dateTime') {
    const date = new Date(type === 'date' ? `${String(value).slice(0, 10)}T12:00:00` : value);
    return Number.isNaN(date.getTime()) ? String(value) : date.toLocaleDateString('es-AR', { day: '2-digit', month: 'short', year: 'numeric' });
  }
  if (type === 'tag') return words[value] || String(value).replaceAll('_', ' ');
  if (type === 'id') return `#${value}`;
  return String(value);
}

function renderDatos() {
  const state = estados[activa.key];
  $('#total-count').textContent = state.loaded ? state.rows.length : '—';
  $('#total-detail').textContent = state.loaded ? (state.error ? 'Datos de la última consulta correcta' : `En ${activa.titulo.toLowerCase()}`) : 'Pendiente de consulta';
  $('#last-update').textContent = state.updated ? state.updated.toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false }) : '—';
  const status = $('#service-status');
  status.textContent = state.loading ? 'Consultando servicio…' : state.error ? 'Consulta fallida' : state.loaded ? 'Consulta completada' : 'Sin consultar';
  status.className = `summary-detail status-detail ${state.error ? 'is-error' : state.loaded && !state.loading ? 'is-ok' : ''}`;
  $('#refresh').disabled = state.loading;
  $('#new-record').disabled = state.loading;
  $('#refresh').classList.toggle('is-loading', state.loading);
  $('#data-region').setAttribute('aria-busy', String(state.loading));
  mensaje($('#load-error'), state.error ? `${state.error}${state.loaded ? ' Se muestran los últimos datos obtenidos.' : ''}` : '');
  const query = normalizar(state.query.trim());
  const rows = state.rows.filter(row => activa.columnas.some(([key, , type]) => normalizar(display(row[key], type)).includes(query)));
  const body = $('#table-body');
  body.replaceChildren();
  const fragment = document.createDocumentFragment();
  for (const row of rows) {
    const tr = node('tr');
    for (const [key, , type] of activa.columnas) {
      const value = row[key];
      const td = node('td', type === 'ARS' || type === 'USD' ? 'numeric' : type === 'mono' || type === 'id' ? 'mono' : '');
      if (type === 'person') {
        const wrap = node('div', 'person-cell');
        const initials = String(value || '?').trim().split(/\s+/).slice(0, 2).map(word => word[0]).join('');
        wrap.append(node('span', 'avatar', initials), node('strong', '', display(value, type)));
        td.append(wrap);
      } else if (value == null || value === '') {
        td.append(node('span', 'unavailable', 'No disponible'));
      } else if (type === 'tag') {
        td.append(node('span', 'tag', display(value, type)));
      } else {
        td.textContent = display(value, type);
        if (type === 'strong') td.classList.add('strong-cell');
      }
      tr.append(td);
    }
    const actions = node('td', 'row-actions');
    for (const [action, symbol, label] of [['edit', 'edit', 'Editar'], ['delete', 'trash', 'Eliminar']]) {
      const button = node('button', `button icon-button plain ${action === 'delete' ? 'delete-action' : ''}`);
      button.type = 'button';
      button.disabled = state.loading;
      button.innerHTML = icon(symbol);
      button.title = `${label} ${activa.singular} #${row.id}`;
      button.setAttribute('aria-label', button.title);
      button.addEventListener('click', () => action === 'edit' ? abrirFormulario(row) : confirmarBorrado(row));
      actions.append(button);
    }
    tr.append(actions);
    fragment.append(tr);
  }
  body.append(fragment);
  const empty = $('#empty-state');
  empty.hidden = rows.length > 0;
  if (!rows.length) {
    empty.replaceChildren();
    const symbol = node('span', 'empty-symbol');
    symbol.innerHTML = icon(state.loading ? 'refresh' : query ? 'search' : activa.icon);
    empty.append(symbol, node('h3', '', state.loading ? 'Cargando registros…' : state.error && !state.loaded ? 'No pudimos cargar los registros' : query ? 'Sin coincidencias' : 'Un buen lugar para empezar'),
      node('p', '', state.loading ? 'Estamos consultando la API de este módulo.' : state.error && !state.loaded ? 'Usá el botón de actualizar para volver a consultar.' : query ? 'Probá con otro nombre, identificador o importe.' : `Todavía no hay registros. Agregá tu primer ${activa.singular}.`));
    if (query && !state.loading) {
      const clear = node('button', 'button secondary', 'Limpiar búsqueda');
      clear.addEventListener('click', () => { state.query = ''; $('#search').value = ''; renderDatos(); $('#search').focus(); });
      empty.append(clear);
    }
  }
  $('#results-summary').textContent = state.loaded ? `${rows.length} de ${state.rows.length} registros${state.error ? ' · Datos anteriores' : ''}` : state.loading ? 'Cargando…' : 'Sin datos disponibles';
}

function abrirFormulario(row = null) {
  if (guardando || borrando) return;
  const entidad = activa;
  edicion = { entidad, row };
  $('#record-form').reset();
  $('#dialog-symbol').innerHTML = icon(entidad.icon);
  $('#record-title').textContent = row ? `Editar ${entidad.singular} #${row.id}` : `Agregar ${entidad.singular}`;
  $('#record-description').textContent = 'Completá los datos del registro. Usá información ficticia para este laboratorio.';
  const fields = $('#form-fields');
  fields.replaceChildren();
  for (const field of entidad.campos) {
    const group = node('div', 'field');
    const label = node('label', '', `${field.label}${field.optional ? ' (opcional)' : ''}`);
    const id = `field-${field.name}`;
    label.htmlFor = id;
    const input = node(field.type === 'select' ? 'select' : 'input');
    input.id = id;
    input.name = field.name;
    input.required = !field.optional;
    if (field.type === 'select') {
      const options = [...field.options];
      if (row?.[field.name] && !options.some(([value]) => value === row[field.name])) options.push([row[field.name], row[field.name]]);
      for (const [value, text] of options) {
        const option = node('option', '', text);
        option.value = value;
        input.append(option);
      }
    } else {
      input.type = field.type;
      input.placeholder = field.placeholder || '';
      input.autocomplete = field.autocomplete || 'off';
      if (field.max) input.maxLength = field.max;
      if (field.type === 'number') {
        input.min = field.integer ? '1' : '0';
        input.step = field.integer ? '1' : '0.01';
        input.max = field.integer ? '2147483647' : '9999999999.99';
      }
      if (field.suggestions) {
        input.setAttribute('list', `${id}-options`);
        const datalist = node('datalist');
        datalist.id = `${id}-options`;
        for (const value of field.suggestions) { const option = node('option'); option.value = value; datalist.append(option); }
        group.append(datalist);
      }
    }
    if (row) input.value = row[field.name] ?? '';
    input.addEventListener('input', () => input.setCustomValidity(''));
    group.append(label, input);
    fields.append(group);
  }
  mensaje($('#form-note'), entidad.nota || 'Los campos sin la indicación “opcional” son obligatorios.');
  mensaje($('#form-error'), '');
  $('#save-record').textContent = row ? 'Guardar cambios' : 'Crear registro';
  $('#record-dialog').showModal();
  fields.querySelector('input, select')?.focus();
}

function busyForm(value) {
  guardando = value;
  for (const input of $('#record-form').querySelectorAll('input, select, button')) input.disabled = value;
  $('#save-record').textContent = value ? 'Guardando…' : edicion.row ? 'Guardar cambios' : 'Crear registro';
}

$('#record-form').addEventListener('submit', async event => {
  event.preventDefault();
  if (guardando) return;
  const { entidad, row } = edicion;
  const body = {};
  for (const field of entidad.campos) {
    const input = $(`#field-${field.name}`);
    const value = input.value.trim();
    if (!value && !field.optional) {
      input.setCustomValidity('Completá este campo; no puede contener solo espacios.');
      input.reportValidity();
      return;
    }
    body[field.name] = field.type === 'number' ? Number(value) : value;
  }
  // Algunas APIs devuelven 404 si un UPDATE no cambia ninguna fila.
  if (row && entidad.campos.every(field => field.type === 'number' ? Number(row[field.name]) === body[field.name] : String(row[field.name] ?? '') === body[field.name])) {
    $('#record-dialog').close();
    notify('No hay cambios para guardar.');
    return;
  }
  busyForm(true);
  mensaje($('#form-error'), '');
  try {
    const result = await request(entidad.key, { method: row ? 'PUT' : 'POST', id: row?.id, body });
    $('#record-dialog').close();
    const missing = entidad.key === 'pagos' && result?.monto_usd == null ? ' La cotización USD no está disponible.'
      : entidad.key === 'transacciones' && !result?.pais ? ' El país no está disponible.' : '';
    notify(`Registro ${row ? 'actualizado' : 'creado'} correctamente.${missing}`, Boolean(missing));
    estados[entidad.key].query = '';
    if (activa.key === entidad.key) $('#search').value = '';
    await cargar(entidad.key);
  } catch (error) { mensaje($('#form-error'), error.message); }
  finally { busyForm(false); }
});

function confirmarBorrado(row) {
  if (guardando || borrando) return;
  eliminacion = { entidad: activa, row };
  const name = row.nombre || row.numero || row.alias || `#${row.id}`;
  $('#delete-description').textContent = `Vas a eliminar ${activa.singular} “${name}” (ID ${row.id}). Esta acción no se puede deshacer desde el panel.`;
  mensaje($('#delete-error'), '');
  $('#delete-dialog').showModal();
}

$('#confirm-delete').addEventListener('click', async () => {
  if (borrando) return;
  borrando = true;
  const { entidad, row } = eliminacion;
  $('#confirm-delete').disabled = true;
  $('#cancel-delete').disabled = true;
  $('#confirm-delete').textContent = 'Eliminando…';
  mensaje($('#delete-error'), '');
  try {
    await request(entidad.key, { method: 'DELETE', id: row.id });
    $('#delete-dialog').close();
    notify('Registro eliminado correctamente.');
    await cargar(entidad.key);
  } catch (error) { mensaje($('#delete-error'), error.message); }
  finally {
    borrando = false;
    $('#confirm-delete').disabled = false;
    $('#cancel-delete').disabled = false;
    $('#confirm-delete').textContent = 'Eliminar registro';
  }
});

$('#new-record').addEventListener('click', () => abrirFormulario());
$('#refresh').addEventListener('click', () => cargar(activa.key));
$('#search').addEventListener('input', event => { estados[activa.key].query = event.target.value; renderDatos(); });
for (const button of document.querySelectorAll('[data-close="record"]')) button.addEventListener('click', () => { if (!guardando) $('#record-dialog').close(); });
$('#cancel-delete').addEventListener('click', () => { if (!borrando) $('#delete-dialog').close(); });
$('#record-dialog').addEventListener('cancel', event => { if (guardando) event.preventDefault(); });
$('#delete-dialog').addEventListener('cancel', event => { if (borrando) event.preventDefault(); });
// Si se borró la fila enfocada, el foco vuelve a una acción estable del módulo.
for (const dialog of document.querySelectorAll('dialog')) dialog.addEventListener('close', () => { $('#new-record').focus(); });
window.addEventListener('hashchange', seleccionar);
seleccionar();
