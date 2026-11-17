// Brainrot Hunter: penyalin entri ke folder output dan penulis dossier.
// Menyalin game.rbxl, PLAY.json, src/, dan screenshots/ dari sebelah file
// ini, lalu menulis dossier.json dari buildDossier vendor make.fun.
import { copyFileSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

const CAPS = {
	text_max_bytes: 65536,
	screenshots: { max: 4, max_bytes: 262144 },
	max_instances: 500000,
	scripts_max_source_bytes: 8388608,
	scripts_max_path_chars: 1048576,
};

function salinFolder(sumber: string, tujuan: string): void {
	mkdirSync(tujuan, { recursive: true });
	for (const nama of readdirSync(sumber)) {
		if (nama.startsWith(".")) {
			continue;
		}
		const asal = join(sumber, nama);
		const akhir = join(tujuan, nama);
		if (statSync(asal).isDirectory()) {
			salinFolder(asal, akhir);
		} else {
			copyFileSync(asal, akhir);
		}
	}
}

const diSini = fileURLToPath(new URL(".", import.meta.url));
const keluaran = process.env.MAKEFUN_OUTPUT_DIR || "/output";
mkdirSync(keluaran, { recursive: true });

for (const berkas of ["game.rbxl", "PLAY.json"]) {
	const asal = join(diSini, berkas);
	if (existsSync(asal)) {
		copyFileSync(asal, join(keluaran, basename(berkas)));
	}
}
for (const folder of ["src", "screenshots"]) {
	const asal = join(diSini, folder);
	if (existsSync(asal)) {
		salinFolder(asal, join(keluaran, folder));
	}
}

const dossier = buildDossier(keluaran, CAPS);
writeFileSync(join(keluaran, "dossier.json"), dossier);
console.log("dossier ditulis: " + join(keluaran, "dossier.json") + " (" + dossier.length + " byte)");
