<template>
  <div style="position:relative;width:100%;height:100%">
    <div v-if="!pickup || !dropoff" style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;background:#dfe1e4;color:#aab0b8">
      <div style="text-align:center">
        <iconify-icon icon="tabler:map-off" width="40"></iconify-icon>
        <div style="font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;margin-top:8px">No route data</div>
      </div>
    </div>
    <div v-else ref="mapContainer" style="width:100%;height:100%" />
    <div style="position:absolute;top:12px;left:12px;font-family:'IBM Plex Mono',monospace;font-size:9px;letter-spacing:0.08em;text-transform:uppercase;color:#6b7280;background:rgba(255,255,255,0.85);padding:4px 9px;border-radius:7px">Route preview</div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch } from "vue";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import gtaMapUrl from "@/assets/maps/gta_map.jpg";

type Coords = { x: number; y: number; z: number } | null;

const props = defineProps<{
  pickup: Coords;
  pickupLabel?: string;
  dropoff: Coords;
  dropoffLabel?: string;
}>();

const mapContainer = ref<HTMLDivElement>();
let map: L.Map | null = null;
let routeLayer: L.LayerGroup | null = null;

// GTA V world-coordinate → map-image-pixel conversion (identical constants as vinewood_blipmanager)
const IMG_WIDTH = 4096;
const IMG_HEIGHT = 6144;
const SCALE_X = 0.454685;
const SCALE_Y = -0.45483;
const OFFSET_X = 1882.72;
const OFFSET_Y = 3826.58;

function gtaToLatLng(x: number, y: number): L.LatLngExpression {
  const lng = x * SCALE_X + OFFSET_X;
  const lat = IMG_HEIGHT - (y * SCALE_Y + OFFSET_Y);
  return [lat, lng];
}

function pinIcon(color: string, icon: string): L.DivIcon {
  return L.divIcon({
    className: "route-marker",
    html: `<div class="route-marker-pin" style="background:${color};">
             <iconify-icon icon="${icon}" width="14" style="color:#fff"></iconify-icon>
           </div>`,
    iconSize: [26, 32],
    iconAnchor: [13, 32],
  });
}

function renderRoute() {
  if (!map || !routeLayer || !props.pickup || !props.dropoff) return;

  routeLayer.clearLayers();

  const from = gtaToLatLng(props.pickup.x, props.pickup.y);
  const to = gtaToLatLng(props.dropoff.x, props.dropoff.y);

  L.imageOverlay(gtaMapUrl, [[0, 0], [IMG_HEIGHT, IMG_WIDTH]]).addTo(routeLayer);

  L.polyline([from, to], {
    color: "#E8B408",
    weight: 3,
    dashArray: "6 8",
    lineCap: "round",
  }).addTo(routeLayer);

  L.marker(from, { icon: pinIcon("#2f9e63", "tabler:map-pin-filled") })
    .bindTooltip(props.pickupLabel || "Pickup", { direction: "top", offset: [0, -28], className: "route-tooltip" })
    .addTo(routeLayer);

  L.marker(to, { icon: pinIcon("#22262d", "tabler:flag-filled") })
    .bindTooltip(props.dropoffLabel || "Drop-off", { direction: "top", offset: [0, -28], className: "route-tooltip" })
    .addTo(routeLayer);

  map.fitBounds(L.latLngBounds([from, to]), { padding: [48, 48], maxZoom: 1 });
}

function initMap() {
  if (!mapContainer.value) return;

  map = L.map(mapContainer.value, {
    crs: L.CRS.Simple,
    minZoom: -3,
    maxZoom: 2,
    zoomControl: false,
    attributionControl: false,
    dragging: false,
    scrollWheelZoom: false,
    doubleClickZoom: false,
    boxZoom: false,
    keyboard: false,
    touchZoom: false,
  });

  routeLayer = L.layerGroup().addTo(map);
  renderRoute();
}

watch(() => [props.pickup, props.dropoff], () => {
  renderRoute();
});

onMounted(() => {
  initMap();
});

onBeforeUnmount(() => {
  if (map) {
    map.remove();
    map = null;
    routeLayer = null;
  }
});
</script>

<style>
.route-tooltip {
  background: rgba(0, 0, 0, 0.85) !important;
  border: 1px solid rgba(255, 255, 255, 0.2) !important;
  color: #fff !important;
  font-size: 11px !important;
  font-family: "Chakra Petch", sans-serif !important;
  padding: 4px 8px !important;
  border-radius: 0 !important;
  box-shadow: none !important;
}

.route-tooltip::before {
  border-top-color: rgba(0, 0, 0, 0.85) !important;
}

.leaflet-container {
  background: #dfe1e4 !important;
  cursor: default !important;
}

.route-marker {
  background: transparent !important;
  border: none !important;
}

.route-marker-pin {
  width: 26px;
  height: 26px;
  border-radius: 50% 50% 50% 0;
  transform: rotate(-45deg);
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid rgba(255, 255, 255, 0.9);
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.25);
}

.route-marker-pin iconify-icon {
  transform: rotate(45deg);
}
</style>
