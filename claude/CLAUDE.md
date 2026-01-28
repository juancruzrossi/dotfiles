## Reglas Globales

### Crítico
1. **NUNCA** pushear a `main` - usar PRs
2. **NUNCA** mencionar Claude/AI en commits
3. **SIEMPRE** usar `gh` CLI para PRs con squash & merge
4. **SIEMPRE** borrar branches después de mergear
5. **NUNCA** dejar servers/procesos corriendo al terminar

### Importante
- Siempre usar el Tasks System Management y descomponer las tareas en tareas atómicas, simples, paso a paso, probando cada requerimiento del usuario.

### Respuestas
- Siempre en español
- Comentarios en código: solo si es necesario, breves, en inglés
- No asumir ni inventar - preguntar si hay dudas

### MCPs Disponibles
Si estos MCPs no responden, pedir al usuario que los habilite:

| MCP | Uso |
|-----|-----|
| **Supabase** | Queries SQL, migraciones, tipos TS |
| **Playwright** | Browser automation, testing E2E |
| **Claude in Chrome** | Screenshots, interacción web |
| **Railway** | Deploy, logs, env vars |

### Git
- Conventional Commits en inglés
- Actualizar `CHANGELOG.md` en cambios significativos
- Formato ISO 8601 (YYYY-MM-DD)
