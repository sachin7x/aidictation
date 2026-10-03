export const brand = {
  name: "AI Dictation",
  shortName: "AI Dictation",
  tagline: "Speak naturally. Write clearly. Work faster.",
  description: "A cross-platform voice productivity platform for dictation, refinement, commands, and meetings.",
  logo: "/brand/logo.svg",
  favicon: "/brand/favicon.svg",
  colors: { background:"#f7f7f4", foreground:"#111111", muted:"#6d6d66", surface:"#ffffff", border:"#deded7", accent:"#111111" },
  fonts: { sans:"Inter, ui-sans-serif, system-ui, sans-serif", mono:"ui-monospace, SFMono-Regular, Menlo, monospace" },
  social: { github:"https://github.com/sachin7x/aidictation" },
  downloads: {
    macAppleSilicon:"/download?platform=mac-arm64",
    macIntel:"/download?platform=mac-x64",
    windows:"/download?platform=windows",
    ios:"/download?platform=ios",
    android:"/download?platform=android"
  },
  pricing: {
    free:{name:"Free",price:"Free"},
    pro:{name:"Pro",price:"Configure"},
    growth:{name:"Growth",price:"Configure"},
    enterprise:{name:"Enterprise",price:"Contact"}
  },
  featureFlags:{notetaker:true,commandMode:true,transforms:true,teams:true,mcp:true}
} as const;
