#!/bin/bash
# Prepara uma captura de tela do iPhone para o campo "Screenshot" da compra no app.
#
# Esse campo do App Store Connect valida contra a lista ANTIGA de tamanhos — 1242x2688 e
# 1284x2778 no iPhone — e não contra a lista da vitrine. Uma captura de 1320x2868, que é
# obrigatória nas capturas de 6,9" do app, é recusada aqui.
#
# A mensagem de erro é sempre "The dimensions of one or more screenshots are wrong",
# inclusive quando a dimensão está certa e o problema é outro. Uma captura vinda do iPhone
# carrega três coisas que o validador não aceita e que não aparecem ao olhar a imagem:
#
#   1. canal alfa — o Preview do macOS acrescenta ao redimensionar
#   2. perfil Display P3 e chunk cICP — sinalização de gama larga/HDR
#   3. chunk eXIf — guarda as dimensões originais, que deixam de bater após o redimensionamento
#
# Uso:  tools/preparar-captura-iap.sh entrada.PNG saida.png [largura altura]

set -euo pipefail

ENTRADA=${1:?uso: preparar-captura-iap.sh entrada.PNG saida.png [largura altura]}
SAIDA=${2:?uso: preparar-captura-iap.sh entrada.PNG saida.png [largura altura]}
LARGURA=${3:-1284}
ALTURA=${4:-2778}

SRGB="/System/Library/ColorSync/Profiles/sRGB Profile.icc"
[ -f "$SRGB" ] || { echo "perfil sRGB não encontrado em $SRGB" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

sips --matchTo "$SRGB" "$ENTRADA" --out "$TMP/a.png" >/dev/null
sips -z "$ALTURA" "$LARGURA" "$TMP/a.png" --out "$TMP/b.png" >/dev/null

# O JPEG é o caminho mais curto para achatar: o formato não admite canal alfa nem 16 bits
# por canal, então a conversão de ida e volta resolve os dois de uma vez.
sips -s format jpeg -s formatOptions best "$TMP/b.png" --out "$TMP/c.jpg" >/dev/null
sips -s format png "$TMP/c.jpg" --out "$TMP/d.png" >/dev/null

# Sobram eXIf, pHYs e iTXt, que o sips reescreve sozinho. Mantemos só os chunks que o PNG
# exige mais o sRGB, para não deixar metadado nenhum contradizendo o cabeçalho.
python3 - "$TMP/d.png" "$SAIDA" <<'PY'
import struct, sys

MANTER = {b'IHDR', b'PLTE', b'sRGB', b'IDAT', b'IEND'}

origem, destino = sys.argv[1], sys.argv[2]
dados = open(origem, 'rb').read()
if dados[:8] != b'\x89PNG\r\n\x1a\n':
    sys.exit('arquivo não é PNG')

saida, i, descartados = bytearray(dados[:8]), 8, []
while i < len(dados):
    tamanho = struct.unpack('>I', dados[i:i + 4])[0]
    tipo = dados[i + 4:i + 8]
    if tipo in MANTER:
        saida += dados[i:i + 12 + tamanho]
    else:
        descartados.append(tipo.decode('latin1'))
    i += 12 + tamanho
    if tipo == b'IEND':
        break

open(destino, 'wb').write(bytes(saida))
print('  chunks removidos:', ', '.join(descartados) or 'nenhum')
PY

echo "  $SAIDA"
sips -g pixelWidth -g pixelHeight -g hasAlpha -g bitsPerSample "$SAIDA" | tail -n +2
