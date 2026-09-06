const fs = require("fs");
const path = require("path");

function copyFolder(src, dest) {
  if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
  for (const item of fs.readdirSync(src)) {
    if (item === ".vercel") continue;
    const s = path.join(src, item);
    const d = path.join(dest, item);
    if (fs.statSync(s).isDirectory()) {
      copyFolder(s, d);
    } else {
      fs.copyFileSync(s, d);
    }
  }
}

if (!fs.existsSync(".vercel")) fs.mkdirSync(".vercel", { recursive: true });
fs.writeFileSync(
  ".vercel/project.json",
  JSON.stringify(
    {
      projectId: "prj_5TPNlIQdcx2ExZjqtBgQQ5ygLPqm",
      orgId: "team_wj4pgE2UpSkatZhp1Z60cBQ4",
      projectName: "spark-lingo"
    },
    null,
    2
  )
);

copyFolder("build/web", ".vercel/output/static");
fs.writeFileSync(
  ".vercel/output/config.json",
  JSON.stringify(
    {
      version: 3,
      routes: [
        { handle: "filesystem" },
        { src: "/.*", dest: "/index.html" }
      ]
    },
    null,
    2
  )
);

console.log("Vercel prebuilt bundle configured successfully!");
