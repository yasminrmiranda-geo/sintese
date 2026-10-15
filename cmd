<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GeoPortal - Conceição do Mato Dentro / MG</title>
  
  <!-- Leaflet CSS -->
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <!-- Chart.js -->
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <!-- Three.js para o Modelo 3D -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>

  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
    body { display: flex; flex-direction: column; height: 100vh; background-color: #f4f6f8; color: #333; }

    header { background-color: #1b4332; color: white; padding: 15px 20px; display: flex; justify-content: space-between; align-items: center; }
    header h1 { font-size: 1.4rem; }

    .main-container { display: flex; flex: 1; overflow: hidden; }

    /* Painel Lateral de Controle */
    .sidebar { width: 320px; background: white; border-right: 1px solid #ccc; padding: 20px; overflow-y: auto; display: flex; flex-direction: column; gap: 20px; }
    .sidebar h2 { font-size: 1.1rem; color: #2d6a4f; margin-bottom: 10px; border-bottom: 2px solid #2d6a4f; padding-bottom: 5px; }

    .layer-group label { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; cursor: pointer; font-size: 0.95rem; }

    /* Área de Conteúdo Visual */
    .content-area { flex: 1; display: grid; grid-template-rows: 1fr 1fr; grid-template-columns: 1fr 1fr; gap: 10px; padding: 10px; background: #e9ecef; }

    .card { background: white; border-radius: 8px; overflow: hidden; position: relative; box-shadow: 0 2px 6px rgba(0,0,0,0.1); display: flex; flex-direction: column; }
    .card-title { background: #2d6a4f; color: white; padding: 8px 12px; font-size: 0.9rem; font-weight: bold; }

    /* Componente 1: Comparador Antes e Depois */
    .before-after-container { position: relative; width: 100%; height: 100%; overflow: hidden; }
    .img-layer { position: absolute; top: 0; left: 0; width: 100%; height: 100%; background-size: cover; background-position: center; }
    .img-after { background-image: url('https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=1000&auto=format&fit=crop'); }
    .img-before { background-image: url('https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=1000&auto=format&fit=crop'); width: 50%; border-right: 3px solid #fff; z-index: 2; }
    .slider-handle { position: absolute; top: 0; bottom: 0; left: 50%; width: 4px; background: white; cursor: ew-resize; z-index: 3; }

    /* Componente 2: Mapa Leaflet */
    #map { width: 100%; height: 100%; }

    /* Componente 3: Modelo 3D */
    #canvas3d { width: 100%; height: 100%; background: #111; }

    /* Componente 4: Gráfico Demográfico */
    .chart-container { padding: 10px; height: 100%; display: flex; justify-content: center; align-items: center; }
  </style>
</head>
<body>

  <header>
    <h1>GeoPortal - Conceição do Mato Dentro / MG</h1>
    <span>Dados Demográficos & Análise Espacial</span>
  </header>

  <div class="main-container">
    <!-- Barra Lateral -->
    <aside class="sidebar">
      <section>
        <h2>Camadas do Mapa</h2>
        <div class="layer-group">
          <label><input type="checkbox" id="layerPop" checked onchange="toggleLayer('pop')"> População por Setores</label>
          <label><input type="checkbox" id="layerRenda" onchange="toggleLayer('renda')"> Renda Média Domiciliar</label>
          <label><input type="checkbox" id="layerEquip" checked onchange="toggleLayer('equip')"> Equipamentos Públicos</label>
        </div>
      </section>

      <section>
        <h2>Modelo 3D</h2>
        <div class="layer-group">
          <label><input type="checkbox" id="layerRelevo" checked onchange="toggle3D('relevo')"> Malha Urbana 3D</label>
          <label><input type="checkbox" id="layerEdificacoes" checked onchange="toggle3D('edif')"> Edificações Públicas</label>
        </div>
      </section>
    </aside>

    <!-- Visualizadores Principais -->
    <main class="content-area">
      
      <!-- Card 1: Antes e Depois (Deslize) -->
      <div class="card">
        <div class="card-title">Evolução Temporal / Imagens de Satélite</div>
        <div class="before-after-container" id="sliderContainer">
          <div class="img-layer img-after"></div>
          <div class="img-layer img-before" id="imgBefore"></div>
          <input type="range" min="0" max="100" value="50" style="position: absolute; bottom: 10px; left: 10%; width: 80%; z-index: 10;" id="rangeSlider">
        </div>
      </div>

      <!-- Card 2: Mapa Interativo -->
      <div class="card">
        <div class="card-title">Mapa Interativo Demográfico</div>
        <div id="map"></div>
      </div>

      <!-- Card 3: Visualizador 3D -->
      <div class="card">
        <div class="card-title">Visualizador 3D Urbano/Topográfico</div>
        <div id="canvas3d"></div>
      </div>

      <!-- Card 4: Gráfico Demográfico -->
      <div class="card">
        <div class="card-title">Perfil Demográfico (Censo IBGE)</div>
        <div class="chart-container">
          <canvas id="demoChart"></canvas>
        </div>
      </div>

    </main>
  </div>

  <!-- Leaflet JS -->
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

  <script>
    // --- 1. SLIDER ANTES E DEPOIS ---
    const rangeSlider = document.getElementById('rangeSlider');
    const imgBefore = document.getElementById('imgBefore');
    rangeSlider.addEventListener('input', (e) => {
      imgBefore.style.width = e.target.value + '%';
    });

    // --- 2. MAPA INTERATIVO (Leaflet) ---
    // Coordenadas aproximadas de Conceição do Mato Dentro: -19.0372, -43.4253
    const map = L.map('map').setView([-19.0372, -43.4253], 13);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    // Marcadores demonstrativos
    const centroMarker = L.marker([-19.0372, -43.4253]).addTo(map)
      .bindPopup('<b>Centro - Conceição do Mato Dentro</b><br>População Estimada: ~18.000 hab.');

    function toggleLayer(type) {
      if(type === 'equip') {
        if(document.getElementById('layerEquip').checked) {
          centroMarker.addTo(map);
        } else {
          map.removeLayer(centroMarker);
        }
      }
    }

    // --- 3. MODELO 3D (Three.js) ---
    const container3d = document.getElementById('canvas3d');
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x1a1a2e);

    const camera = new THREE.PerspectiveCamera(60, container3d.clientWidth / container3d.clientHeight, 0.1, 1000);
    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(container3d.clientWidth, container3d.clientHeight);
    container3d.appendChild(renderer.domElement);

    // Iluminação
    const light = new THREE.DirectionalLight(0xffffff, 1);
    light.position.set(5, 10, 7).normalize();
    scene.add(light);
    scene.add(new THREE.AmbientLight(0x404040));

    // Bloco simulando relevo/edificação 3D
    const geometry = new THREE.BoxGeometry(2, 1, 2);
    const material = new THREE.MeshLambertMaterial({ color: 0x2d6a4f });
    const cube = new THREE.Mesh(geometry, material);
    scene.add(cube);

    camera.position.set(3, 3, 4);
    camera.lookAt(0, 0, 0);

    function animate3D() {
      requestAnimationFrame(animate3D);
      cube.rotation.y += 0.005;
      renderer.render(scene, camera);
    }
    animate3D();

    function toggle3D(layer) {
      if(layer === 'edif') {
        cube.visible = document.getElementById('layerEdificacoes').checked;
      }
    }

    // --- 4. GRÁFICO DEMOGRÁFICO (Chart.js) ---
    const ctx = document.getElementById('demoChart').getContext('2d');
    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['Feminino', 'Masculino', 'Até 19 anos', '20-59 anos', '60+ anos'],
        datasets: [{
          label: 'Distribuição Demográfica (%)',
          data: [50.8, 49.2, 26.5, 58.2, 15.3],
          backgroundColor: ['#2d6a4f', '#1b4332', '#52b788', '#74c69d', '#d8f3dc']
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } }
      }
    });

    // Ajuste de redimensionamento de janela
    window.addEventListener('resize', () => {
      renderer.setSize(container3d.clientWidth, container3d.clientHeight);
      camera.aspect = container3d.clientWidth / container3d.clientHeight;
      camera.updateProjectionMatrix();
    });
  </script>
</body>
</html>
