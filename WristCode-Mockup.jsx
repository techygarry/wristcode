import { useState, useEffect } from "react";

const T = {
  bg: "#0F1117", bgCard: "#161B22", orange: "#E8732A",
  text: "#E0E0E0", textDim: "#8B949E", green: "#2ECC71",
  red: "#E74C3C", yellow: "#F39C12", blue: "#58A6FF",
  cyan: "#79C0FF", border: "#2D333B", inputBg: "#1C2128",
};

const PixelMascot = ({ size = 28 }) => {
  const p = size / 7;
  const body = [[1,0],[2,0],[4,0],[5,0],[0,1],[1,1],[2,1],[3,1],[4,1],[5,1],[6,1],[0,2],[1,2],[2,2],[3,2],[4,2],[5,2],[6,2],[1,3],[2,3],[4,3],[5,3],[0,4],[1,4],[2,4],[3,4],[4,4],[5,4],[6,4],[0,5],[2,5],[3,5],[4,5],[6,5],[0,6],[1,6],[5,6],[6,6]];
  const holes = [[2,2],[4,2],[2,4],[3,4],[4,4]];
  return (
    <svg width={size} height={size} viewBox={`0 0 ${7*p} ${7*p}`}>
      {body.map(([x,y],i)=><rect key={i} x={x*p} y={y*p} width={p} height={p} fill={T.orange} rx={0.3}/>)}
      {holes.map(([x,y],i)=><rect key={`h${i}`} x={x*p} y={y*p} width={p} height={p} fill={T.bg}/>)}
    </svg>
  );
};

const Dot = ({ color = T.green, size = 6 }) => (
  <span style={{ display:"inline-block", width:size, height:size, borderRadius:"50%", background:color, boxShadow:`0 0 4px ${color}66`, marginRight:3 }}/>
);

const WatchFrame = ({ children, screen, setScreen }) => {
  const names = ["Welcome","Sessions","Terminal","Diff","Settings"];
  return (
    <div style={{ display:"flex", flexDirection:"column", alignItems:"center", gap:16 }}>
      <div style={{ position:"relative", width:220, height:270, background:"linear-gradient(145deg,#2A2A2E,#1A1A1E)", borderRadius:48, padding:14, boxShadow:"0 8px 32px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.05)" }}>
        <div style={{ position:"absolute", right:-6, top:75, width:8, height:28, borderRadius:4, background:"linear-gradient(180deg,#3A3A3E,#2A2A2E)", boxShadow:"2px 0 4px rgba(0,0,0,0.4)" }}/>
        <div style={{ position:"absolute", right:-5, top:115, width:6, height:16, borderRadius:3, background:"linear-gradient(180deg,#3A3A3E,#2A2A2E)" }}/>
        <div style={{ width:"100%", height:"100%", background:T.bg, borderRadius:36, overflow:"hidden" }}>
          <div style={{ width:"100%", height:"100%", overflowY:"auto", overflowX:"hidden", padding:"8px 6px", fontFamily:"'SF Mono','Menlo','Consolas',monospace", fontSize:8, color:T.text, scrollbarWidth:"none" }}>
            {children}
          </div>
        </div>
      </div>
      <div style={{ display:"flex", gap:5 }}>
        {names.map((s,i)=>(
          <button key={s} onClick={()=>setScreen(i)} style={{ padding:"5px 9px", fontSize:10, fontFamily:"'SF Mono',monospace", background:screen===i?T.orange:T.bgCard, color:screen===i?"#fff":T.textDim, border:`1px solid ${screen===i?T.orange:T.border}`, borderRadius:4, cursor:"pointer", transition:"all 0.2s" }}>{s}</button>
        ))}
      </div>
    </div>
  );
};

const WelcomeScreen = () => {
  const [dots,setDots] = useState("");
  useEffect(()=>{ const iv=setInterval(()=>setDots(d=>d.length>=3?"":d+"."),500); return ()=>clearInterval(iv); },[]);
  return (
    <div style={{fontSize:7}}>
      <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"2px 4px", marginBottom:4 }}>
        <div style={{ display:"flex", alignItems:"center", gap:3 }}>
          <PixelMascot size={12}/><span style={{color:T.text,fontWeight:700,fontSize:8}}>claude</span><span style={{color:T.textDim,fontSize:7}}>+</span>
        </div>
        <div style={{display:"flex",gap:3}}><span style={{color:T.textDim}}>─</span><span style={{color:T.textDim}}>×</span></div>
      </div>
      <div style={{ border:`1px solid ${T.orange}`, borderRadius:3, padding:"3px 6px", margin:"0 4px 6px" }}>
        <span style={{color:T.orange,fontSize:7.5,fontWeight:600}}>WristCode</span><span style={{color:T.textDim,fontSize:6.5}}> v1.0.0</span>
      </div>
      <div style={{padding:"0 4px",marginBottom:6}}>
        <div style={{color:T.text,fontWeight:700,fontSize:9,marginBottom:6}}>Welcome back Garry!</div>
        <div style={{display:"flex",gap:6}}>
          <PixelMascot size={28}/>
          <div style={{ border:`1px solid ${T.orange}`, borderRadius:3, padding:4, flex:1 }}>
            <div style={{color:T.orange,fontSize:6.5,fontWeight:600,marginBottom:2}}>Tips for getting started</div>
            <div style={{color:T.textDim,fontSize:5.5,lineHeight:1.4}}>Tap mic to send voice prompts. Swipe for sessions.</div>
          </div>
        </div>
      </div>
      <div style={{ padding:"4px 6px", margin:"0 4px 4px", background:T.bgCard, borderRadius:3, borderLeft:`2px solid ${T.green}` }}>
        <div style={{display:"flex",alignItems:"center",gap:3}}><Dot color={T.green} size={5}/><span style={{color:T.green,fontSize:6.5}}>Connected via Wi-Fi</span></div>
        <div style={{color:T.textDim,fontSize:5.5,marginTop:1}}>Bridge: MacBook-Pro.local:3847</div>
      </div>
      <div style={{padding:"0 4px"}}>
        <div style={{color:T.orange,fontSize:6.5,fontWeight:600,marginBottom:3}}>Recent activity</div>
        {[{name:"solar-crm",time:"2m ago",s:T.green},{name:"mitimaiti-app",time:"1h ago",s:T.yellow},{name:"wristcode-bridge",time:"3h ago",s:T.textDim}].map((r,i)=>(
          <div key={i} style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"2px 4px", background:i===0?T.bgCard:"transparent", borderRadius:2, marginBottom:1 }}>
            <div style={{display:"flex",alignItems:"center",gap:3}}><Dot color={r.s} size={4}/><span style={{color:T.text,fontSize:6.5}}>{r.name}</span></div>
            <span style={{color:T.textDim,fontSize:5.5}}>{r.time}</span>
          </div>
        ))}
      </div>
      <div style={{ marginTop:6, padding:"3px 4px", borderTop:`1px solid ${T.border}` }}>
        <span style={{color:T.blue,fontSize:6}}>= /</span><span style={{color:T.textDim,fontSize:5.5}}> type a command{dots}</span>
      </div>
    </div>
  );
};

const SessionsScreen = () => (
  <div style={{fontSize:7}}>
    <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"2px 4px 6px", borderBottom:`1px solid ${T.border}`, marginBottom:6 }}>
      <div style={{display:"flex",alignItems:"center",gap:3}}><PixelMascot size={10}/><span style={{color:T.orange,fontWeight:700,fontSize:8}}>Sessions</span></div>
      <span style={{color:T.textDim,fontSize:6.5}}>3 active</span>
    </div>
    {[{name:"solar-crm",id:"a3f2c1",model:"Sonnet 4.5",s:T.green,l:"running",t:"2m"},{name:"mitimaiti-app",id:"b7d4e2",model:"Opus 4.6",s:T.yellow,l:"waiting",t:"1h"},{name:"wristcode-bridge",id:"c9a1f3",model:"Sonnet 4.5",s:T.textDim,l:"idle",t:"3h"}].map((s,i)=>(
      <div key={i} style={{ background:T.bgCard, borderLeft:`2px solid ${i===0?T.orange:T.border}`, borderRadius:3, padding:"5px 6px", marginBottom:4, marginLeft:4, marginRight:4 }}>
        <div style={{display:"flex",justifyContent:"space-between",alignItems:"center"}}>
          <span style={{color:T.text,fontWeight:600,fontSize:7.5}}>{s.name}</span>
          <div style={{display:"flex",alignItems:"center",gap:2}}><Dot color={s.s} size={4}/><span style={{color:s.s,fontSize:5.5}}>{s.l}</span></div>
        </div>
        <div style={{display:"flex",justifyContent:"space-between",marginTop:2}}>
          <span style={{color:T.textDim,fontSize:5.5}}>{s.model} · #{s.id}</span>
          <span style={{color:T.textDim,fontSize:5.5}}>{s.t} ago</span>
        </div>
      </div>
    ))}
    <div style={{ border:`1px dashed ${T.orange}`, borderRadius:3, padding:"6px 0", margin:"4px 4px 0", textAlign:"center", cursor:"pointer" }}>
      <span style={{color:T.orange,fontSize:8}}>+ New Session</span>
    </div>
  </div>
);

const TerminalScreen = () => {
  const resp = "I'll add input validation to the auth middleware. Let me check the current implementation first.";
  const [ch,setCh] = useState(0);
  useEffect(()=>{ if(ch<resp.length){ const t=setTimeout(()=>setCh(c=>c+1),25); return()=>clearTimeout(t); } },[ch,resp.length]);
  return (
    <div style={{ fontSize:6.5, display:"flex", flexDirection:"column", minHeight:225 }}>
      <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"1px 3px 3px", borderBottom:`1px solid ${T.border}`, marginBottom:4, flexShrink:0 }}>
        <div style={{display:"flex",alignItems:"center",gap:2}}><PixelMascot size={8}/><span style={{color:T.orange,fontWeight:600,fontSize:6.5}}>solar-crm</span></div>
        <div style={{display:"flex",alignItems:"center",gap:2}}><Dot color={T.green} size={4}/><span style={{color:T.textDim,fontSize:5}}>Sonnet 4.5</span></div>
      </div>
      <div style={{flex:1,overflow:"hidden",padding:"0 2px"}}>
        <div style={{marginBottom:4}}><span style={{color:T.textDim,fontSize:5.5}}>{"❯ "}</span><span style={{color:T.text,fontSize:6.5}}>Add validation to auth flow</span></div>
        <div style={{marginBottom:4,lineHeight:1.5}}>
          <span style={{color:T.text,fontSize:6.5}}>{resp.substring(0,ch)}</span>
          {ch<resp.length && <span style={{color:T.orange}}>▊</span>}
        </div>
        {ch>=resp.length && <>
          <div style={{marginBottom:2}}><span style={{color:T.blue,fontSize:6}}>{"⚡ Read "}</span><span style={{color:T.cyan,fontSize:6}}>src/middleware/auth.ts</span></div>
          <div style={{ background:"#1C2128", borderLeft:`2px solid ${T.blue}`, padding:"3px 4px", borderRadius:2, marginBottom:4, fontSize:5.5 }}>
            <div style={{color:T.textDim}}>Found auth middleware (47 lines)</div>
            <div style={{color:T.textDim}}>Missing: input sanitization, rate limiting</div>
          </div>
          <div style={{marginBottom:2}}><span style={{color:T.yellow,fontSize:6}}>{"✏️ Edit "}</span><span style={{color:T.cyan,fontSize:6}}>src/middleware/auth.ts</span></div>
          <div style={{ background:"#1C2128", padding:"2px 4px", borderRadius:2, fontSize:5.5, marginBottom:3 }}>
            <div style={{color:T.green}}>{"+ if (!email || !isValidEmail(email)) {"}</div>
            <div style={{color:T.green}}>{"+   return res.status(400).json({})"}</div>
            <div style={{color:T.green}}>{"+ }"}</div>
          </div>
          <div style={{color:T.textDim,fontSize:5,textAlign:"right"}}>{"↑ 1.2k ↓ 847 tokens · $0.003"}</div>
        </>}
      </div>
      <div style={{ display:"flex", gap:3, padding:"3px 0", overflowX:"auto", flexShrink:0, borderTop:`1px solid ${T.border}`, marginTop:2 }}>
        {["Status?","Continue","Fix it","Commit"].map(a=>(
          <span key={a} style={{ padding:"2px 5px", background:T.bgCard, border:`1px solid ${T.border}`, borderRadius:8, color:T.textDim, fontSize:5.5, whiteSpace:"nowrap", cursor:"pointer" }}>{a}</span>
        ))}
      </div>
      <div style={{ display:"flex", alignItems:"center", gap:4, padding:"4px 3px 2px", borderTop:`1px solid ${T.border}`, flexShrink:0 }}>
        <div style={{ width:22, height:22, borderRadius:"50%", background:T.orange, display:"flex", alignItems:"center", justifyContent:"center", cursor:"pointer", boxShadow:`0 0 8px ${T.orange}44`, fontSize:10 }}>🎤</div>
        <div style={{ flex:1, background:T.inputBg, border:`1px solid ${T.border}`, borderRadius:4, padding:"3px 5px", color:T.textDim, fontSize:6 }}>Type or speak...</div>
        <span style={{fontSize:8,cursor:"pointer"}}>⌨️</span>
      </div>
      <style>{`@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}`}</style>
    </div>
  );
};

const DiffScreen = () => (
  <div style={{fontSize:6.5}}>
    <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"2px 4px 4px", borderBottom:`1px solid ${T.border}`, marginBottom:4 }}>
      <span style={{color:T.orange,fontWeight:600,fontSize:7}}>Review Changes</span>
      <span style={{ background:T.yellow, color:T.bg, padding:"1px 4px", borderRadius:6, fontSize:5, fontWeight:700 }}>2 files</span>
    </div>
    <div style={{ background:T.bgCard, border:`1px solid ${T.border}`, borderRadius:3, padding:"4px 5px", margin:"0 2px 6px" }}>
      <div style={{color:T.orange,fontSize:5.5,marginBottom:2}}>🤖 Summary</div>
      <div style={{color:T.text,fontSize:6,lineHeight:1.4}}>Added email validation and rate limiting to auth middleware. Returns 400 for invalid inputs.</div>
    </div>
    <div style={{ padding:"2px 4px", background:"#1C2128", borderRadius:"3px 3px 0 0", margin:"0 2px", borderBottom:`1px solid ${T.border}` }}>
      <span style={{color:T.cyan,fontSize:6}}>src/middleware/auth.ts</span><span style={{color:T.textDim,fontSize:5}}> (+12, -3)</span>
    </div>
    <div style={{ margin:"0 2px 6px", background:"#1C2128", borderRadius:"0 0 3px 3px", padding:"3px 0", fontSize:5.5 }}>
      {[
        {t:"ctx",n:"14",c:"export const authenticate = async (req, res) => {"},
        {t:"del",n:"15",c:"  const { email, password } = req.body;"},
        {t:"add",n:"15",c:"  const { email, password } = req.body;"},
        {t:"add",n:"16",c:"  if (!email || !isValidEmail(email)) {"},
        {t:"add",n:"17",c:'    return res.status(400).json({'},
        {t:"add",n:"18",c:'      error: "Invalid email format"'},
        {t:"add",n:"19",c:"    });"},
        {t:"add",n:"20",c:"  }"},
        {t:"ctx",n:"21",c:"  const user = await User.findOne({ email });"},
      ].map((l,i)=>(
        <div key={i} style={{ display:"flex", background:l.t==="add"?"#2ECC7115":l.t==="del"?"#E74C3C15":"transparent", padding:"0 3px", borderLeft:l.t==="add"?`2px solid ${T.green}`:l.t==="del"?`2px solid ${T.red}`:"2px solid transparent" }}>
          <span style={{color:T.textDim,width:16,textAlign:"right",marginRight:4,fontSize:5,userSelect:"none"}}>{l.n}</span>
          <span style={{color:l.t==="add"?T.green:l.t==="del"?T.red:T.textDim,marginRight:3,width:6}}>{l.t==="add"?"+":l.t==="del"?"−":" "}</span>
          <span style={{color:l.t==="ctx"?T.textDim:T.text,whiteSpace:"nowrap"}}>{l.c}</span>
        </div>
      ))}
    </div>
    <div style={{display:"flex",justifyContent:"center",gap:3,marginBottom:6}}>
      <span style={{width:5,height:5,borderRadius:"50%",background:T.orange}}/><span style={{width:5,height:5,borderRadius:"50%",background:T.border}}/>
    </div>
    <div style={{display:"flex",gap:6,padding:"0 10px",justifyContent:"center"}}>
      <div style={{ flex:1, background:"#E74C3C22", border:`2px solid ${T.red}`, borderRadius:6, padding:"8px 0", textAlign:"center", cursor:"pointer" }}>
        <div style={{fontSize:14}}>✕</div><div style={{color:T.red,fontSize:6,fontWeight:600,marginTop:1}}>Reject</div>
      </div>
      <div style={{ flex:1, background:"#2ECC7122", border:`2px solid ${T.green}`, borderRadius:6, padding:"8px 0", textAlign:"center", cursor:"pointer" }}>
        <div style={{fontSize:14}}>✓</div><div style={{color:T.green,fontSize:6,fontWeight:600,marginTop:1}}>Approve</div>
      </div>
    </div>
  </div>
);

const SettingsScreen = () => (
  <div style={{fontSize:6.5}}>
    <div style={{ display:"flex", alignItems:"center", gap:3, padding:"2px 4px 6px", borderBottom:`1px solid ${T.border}`, marginBottom:6 }}>
      <PixelMascot size={10}/><span style={{color:T.orange,fontWeight:700,fontSize:8}}>Settings</span>
    </div>
    {[
      {title:"Bridge Server",items:[{l:"Host",v:"MacBook-Pro.local",c:T.text},{l:"Port",v:"3847",c:T.text},{l:"Status",v:"● Connected",c:T.green},{l:"Tailscale",v:"100.64.1.12",c:T.cyan}]},
      {title:"Voice",items:[{l:"Auto-send",v:"1.5s silence",c:T.text},{l:"TTS Output",v:"ON",c:T.green},{l:"Language",v:"English",c:T.text}]},
      {title:"Display",items:[{l:"Font Size",v:"12pt",c:T.text},{l:"Auto-scroll",v:"ON",c:T.green},{l:"Streaming",v:"Animated",c:T.text}]},
      {title:"Notifications",items:[{l:"Approval",v:"ON",c:T.green},{l:"Complete",v:"ON",c:T.green},{l:"Errors",v:"ON",c:T.yellow}]},
    ].map((sec,si)=>(
      <div key={si} style={{marginBottom:6,padding:"0 4px"}}>
        <div style={{color:T.orange,fontSize:6.5,fontWeight:600,marginBottom:3,borderBottom:`1px solid ${T.border}`,paddingBottom:2}}>{sec.title}</div>
        {sec.items.map((it,ii)=>(
          <div key={ii} style={{display:"flex",justifyContent:"space-between",padding:"2px 0"}}>
            <span style={{color:T.textDim,fontSize:6}}>{it.l}</span><span style={{color:it.c,fontSize:6}}>{it.v}</span>
          </div>
        ))}
      </div>
    ))}
    <div style={{ margin:"4px 4px 0", padding:"4px 0", borderTop:`1px solid ${T.border}`, textAlign:"center" }}>
      <div style={{color:T.textDim,fontSize:5.5}}>WristCode v1.0.0</div>
      <div style={{color:T.textDim,fontSize:5}}>Claude Agent SDK · Max Subscription</div>
    </div>
  </div>
);

export default function App() {
  const [screen,setScreen] = useState(0);
  const S = [WelcomeScreen,SessionsScreen,TerminalScreen,DiffScreen,SettingsScreen][screen];
  return (
    <div style={{ minHeight:"100vh", background:"#08080C", display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", padding:20, fontFamily:"'SF Mono','Menlo','Consolas',monospace" }}>
      <div style={{textAlign:"center",marginBottom:20}}>
        <div style={{display:"flex",alignItems:"center",justifyContent:"center",gap:8,marginBottom:4}}>
          <PixelMascot size={22}/><span style={{color:T.orange,fontSize:20,fontWeight:700,letterSpacing:2}}>WRISTCODE</span>
        </div>
        <div style={{color:T.textDim,fontSize:11}}>Claude Code on Your Wrist · All 5 Screens</div>
      </div>
      <WatchFrame screen={screen} setScreen={setScreen}><S/></WatchFrame>
      <div style={{ marginTop:16, padding:"8px 14px", background:T.bgCard, border:`1px solid ${T.border}`, borderRadius:6, maxWidth:300, textAlign:"center" }}>
        <div style={{color:T.orange,fontSize:10,fontWeight:600,marginBottom:2}}>
          {["Welcome Screen","Session Browser","Terminal View","Diff Reviewer","Settings"][screen]}
        </div>
        <div style={{color:T.textDim,fontSize:9,lineHeight:1.5}}>
          {["Claude Code welcome layout with connection status, pixel mascot, and recent sessions.","Browse active Claude Code sessions. Tap to connect, swipe to end.","Full terminal with streaming output, voice input, and quick action pills.","Review file changes with colored diffs, AI summary, and approve/reject.","Configure bridge server, voice, display, and notification preferences."][screen]}
        </div>
      </div>
    </div>
  );
}
