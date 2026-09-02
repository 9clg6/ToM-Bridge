import { defineConfig } from "bunup";

export default defineConfig({
  name: "tom-bridge",
  compile: {
    outfile: 'tom-bridge',
  },
  emitDCEAnnotations: true,
  entry: "src/index.ts",
  exports: true,
  minify: true,
  packages: "bundle",
});
