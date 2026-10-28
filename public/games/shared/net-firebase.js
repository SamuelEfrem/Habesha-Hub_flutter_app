/*
 * Online racing for Capital Drive 3D, using Firebase Realtime Database.
 * The game calls HabeshaNet.init() once, then room.join(name) for each race room.
 * Every player writes only their own node:  races/<room>/<uid>
 * The node is deleted automatically when the player closes the game (onDisconnect).
 */
(function () {
  function makeRoom(db, uid, name) {
    const base = db.ref("races/" + name);
    const meRef = base.child(uid);
    let mine = {};
    let peers = [];
    let listeners = [];
    let timer = null;

    meRef.onDisconnect().remove();

    function toPeers(val) {
      return Object.entries(val || {}).map(([id, p]) => ({
        peer: id, by: id, isMe: id === uid, sameTab: id === uid,
        kind: "viewer", guest: false,
        presence: Object.freeze(Object.assign({}, p)), updatedAt: Date.now()
      }));
    }
    const onValue = base.on("value", (snap) => {
      peers = toPeers(snap.val());
      listeners.forEach((f) => f({ peers, joined: [], left: [], updated: [] }));
    });

    const api = {
      name,
      presence(patch) {
        Object.assign(mine, patch);
        Object.keys(mine).forEach((k) => { if (mine[k] === null || mine[k] === undefined) delete mine[k]; });
        if (!timer) {
          // send at most ~15 times a second
          timer = setTimeout(() => {
            timer = null;
            meRef.set(Object.assign({}, mine, { t: firebase.database.ServerValue.TIMESTAMP })).catch(() => {});
          }, 66);
        }
        return Promise.resolve();
      },
      peers() {
        return peers.length ? peers : [{ peer: uid, by: uid, isMe: true, sameTab: true, kind: "viewer", guest: false, presence: mine, updatedAt: Date.now() }];
      },
      onPeers(f) {
        listeners.push(f);
        setTimeout(() => f({ peers: api.peers(), joined: [], left: [], updated: [] }), 0);
        return () => { listeners = listeners.filter((x) => x !== f); };
      },
      async leave() {
        base.off("value", onValue);
        listeners = [];
        await meRef.remove().catch(() => {});
      }
    };
    return api;
  }

  window.HabeshaNet = {
    async init() {
      if (!window.firebase || !window.HABESHA_FIREBASE_CONFIG) return null;
      if (!firebase.apps.length) firebase.initializeApp(window.HABESHA_FIREBASE_CONFIG);
      const auth = firebase.auth();
      const user = auth.currentUser || (await auth.signInAnonymously()).user;
      const db = firebase.database();
      return { join: async (name) => makeRoom(db, user.uid, name) };
    }
  };
})();
