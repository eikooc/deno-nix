// Get contents of lockfile
// Parse as json
// Get packages.specifiers.$
// Get packages.jsr.$
// Get packages.npm.$
// Get packages.workspace.dependencies.$
// Construct lock.nix file with URLs and hash

const lockFile = await Deno.readTextFile("deno.lock");
const lockJson = JSON.parse(lockFile);
const packages = lockJson.packages;
const specifiers = packages.specifiers;

const indent = (s) => s.split("\n").map((s) => "  " + s).join("\n");

const buildNixExpression = (name, url, rev, sha256) => {
  return `"${name}" = {
    url = "${url}";
    rev = "${rev}";
    sha256 = "${sha256}";
};`;
};

const lockNix = Object.values(specifiers).map((specifier) => {
  if (specifier.startsWith("jsr")) {
    const jsrKey = specifier.split(":")[1];
    const a = packages.jsr[jsrKey];

    const version = a["version"];
    const integrity = a["integrity"];

    const url = `https://esm.sh/jsr/${jsrKey}`;
    const name = jsrKey.split("@")[1];

    return buildNixExpression(name, url, version, integrity);
  }
  if (specifier === "remote") {
  }
  if (specifier === "npm") {
  }
  const specifierVersion = specifiers[specifier];
  const jsrVersion = jsr[specifier];
  const npmVersion = npm[specifier];

  return `"${specifier}" = {
        version = "${specifierVersion}";
        jsr = "${jsrVersion}";
        npm = "${npmVersion}";
    };`;
}).join("\n");

const lockNixFile = `{
${indent(lockNix)}
}`;

console.log(lockNixFile);

// const HOME = await Deno.env.get("PWD");
// await Deno.writeTextFile(HOME + "/deno.nix", lockNixFile);
