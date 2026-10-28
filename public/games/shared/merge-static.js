// Joins every static mesh under `root` into one mesh per material, so a city of ~1300 boxes
// becomes a few dozen draw calls (the main reason the 3D games were slow on phones).
// Works on any group (positions are kept relative to it). Sprites/points are kept as they are. Call it right after the static city is built.
(function(){
  const ATTRS=["position","normal","uv"];
  const sig=(m,o)=>[m.type,m.color&&m.color.getHex(),m.roughness,m.metalness,m.map&&m.map.uuid,m.emissive&&m.emissive.getHex(),
    m.emissiveIntensity,m.emissiveMap&&m.emissiveMap.uuid,m.flatShading,m.side,m.transparent,m.opacity,m.blending,m.depthWrite,o.castShadow,o.receiveShadow].join("|");
  function part(geo,start,count){const g=new THREE.BufferGeometry();
    ATTRS.forEach(n=>{const a=geo.attributes[n];if(a)g.setAttribute(n,new THREE.BufferAttribute(a.array.slice(start*a.itemSize,(start+count)*a.itemSize),a.itemSize))});return g}
  function join(parts){const total=parts.reduce((s,p)=>s+p.attributes.position.count,0),out=new THREE.BufferGeometry();
    ATTRS.forEach(n=>{const size=n==="uv"?2:3,arr=new Float32Array(total*size);let off=0;
      parts.forEach(p=>{const a=p.attributes[n],c=p.attributes.position.count;if(a)arr.set(a.array,off);off+=c*size});
      out.setAttribute(n,new THREE.BufferAttribute(arr,size))});
    out.computeBoundingSphere();return out}
  window.mergeStatic=function(root){
    root.updateMatrixWorld(true);const groups=new Map(),loose=[],inv=new THREE.Matrix4().copy(root.matrixWorld).invert(),rel=o=>new THREE.Matrix4().multiplyMatrices(inv,o.matrixWorld);
    root.traverse(o=>{
      if(o.isSprite||o.isPoints||o.isLine){loose.push(o);return}
      if(!o.isMesh)return;
      const src=o.geometry.index?o.geometry.toNonIndexed():o.geometry.clone();src.applyMatrix4(rel(o));
      const mats=Array.isArray(o.material)?o.material:[o.material];
      const pieces=Array.isArray(o.material)&&src.groups.length?src.groups.map(gr=>[part(src,gr.start,gr.count),mats[gr.materialIndex]]):[[part(src,0,src.attributes.position.count),mats[0]]];
      pieces.forEach(([g,m])=>{if(!m)return;const k=sig(m,o);if(!groups.has(k))groups.set(k,{m,cast:o.castShadow,recv:o.receiveShadow,parts:[]});groups.get(k).parts.push(g)});
      src.dispose()});
    loose.forEach(o=>{rel(o).decompose(o.position,o.quaternion,o.scale)});
    while(root.children.length)root.remove(root.children[0]);
    groups.forEach(G=>{const mesh=new THREE.Mesh(join(G.parts),G.m);mesh.castShadow=G.cast;mesh.receiveShadow=G.recv;root.add(mesh);G.parts.forEach(p=>p.dispose())});
    loose.forEach(o=>root.add(o));
    return groups.size};
})();
