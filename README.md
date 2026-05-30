# AegisOps Dashboard

Vue3 CDN + SFC + UnoCSS dashboard for the Google Cloud Rapid Agent Hackathon.

Run the V backend first:

```powershell
v run C:\git\v_projects\google_cloud_rapid_agent_hackathon\cmd\agent serve --port 8080
```

Serve this folder:

```powershell
v run tools\static_server.v . 8902
```

Open http://127.0.0.1:8902. The app calls `http://127.0.0.1:8080/api/agent/run`
by default. Override with:

```js
localStorage.setItem('aegisops_api', 'https://YOUR-CLOUD-RUN-URL')
```

If the backend is unavailable, the dashboard switches to a deterministic demo
run so a public GitHub Pages URL remains judgeable.
