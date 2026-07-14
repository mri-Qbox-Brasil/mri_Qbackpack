# mri_Qbackpack — Manual

Sistema de mochilas: aplica o componente visual no ped de quem possui o item e dá a cada mochila um stash persistente próprio.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Configuração](#configuração)
4. [Mochilas (`config.Bags`)](#mochilas-configbags)
5. [Itens no inventário](#itens-no-inventário)
6. [Funcionamento](#funcionamento)
7. [Integrações](#integrações)
8. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
9. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `qb-core` / `qbx_core` | Sim | O nome exato é lido de `config.FrameworkResource`. O recurso usa `GetCoreObject`, `QBCore.Functions.HasItem` e `QBCore.Functions.CreateUseableItem` |
| `ox_inventory` | Sim (modo `ox`) | Modo padrão. Usa `openInventory`, `RegisterStash`, `SetMetadata`, `Search`, `registerHook` |
| `qb-inventory` / `lj-inventory` | Sim (modo `qb`) | Alternativa ao modo `ox`. Usa `inventory:server:OpenInventory` e `SetInventory` |

Não há bloco `dependencies` no `fxmanifest.lua` — a ordem de start precisa ser garantida pelo `server.cfg`.

---

## Instalação

1. Copie a pasta `mri_Qbackpack` para `resources/`.
2. Adicione ao `server.cfg`, depois do framework e do inventário:
   ```
   ensure mri_Qbackpack
   ```
3. Cadastre os itens `backpack1`, `backpack2` e `duffle1` no seu inventário (veja [Itens no inventário](#itens-no-inventário)).
4. Ajuste `shared/config.lua` para o inventário que você usa (`config.InvType` / `config.InvName`).
5. Se usar `ox_inventory` com `qb-core`, aplique o patch de `HasItem` descrito em [Integrações](#integrações) — sem ele o componente visual nunca é aplicado.

O arquivo `IdList.json` na raiz do recurso guarda os IDs de mochila já emitidos e é reescrito em runtime pelo servidor. **Não apague esse arquivo** — perder o conteúdo permite que um ID seja reemitido e duas mochilas passem a compartilhar o mesmo stash.

---

## Configuração

Arquivo: `shared/config.lua`.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `config.FrameworkResource` | string | Sim | Nome do recurso do framework de onde o `GetCoreObject` é chamado. Padrão: `qb-core` |
| `config.InvType` | string | Sim | Tipo de inventário: `ox` ou `qb`. Define qual bloco de código é registrado no client e no server. Padrão: `ox` |
| `config.InvName` | string | Sim | Nome do recurso de inventário instalado (`ox_inventory`, `qb-inventory`, `lj-inventory`…). Padrão: `ox_inventory` |
| `config.Bags` | array | Sim | Lista de mochilas. Uma entrada por item de mochila — ver tabela abaixo |

---

## Mochilas (`config.Bags`)

Cada entrada define um item de mochila, o visual que ele aplica no ped e o tamanho do stash que ele abre.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `ComponentId` | number | Não | Slot de componente do GTA V. Padrão quando omitido: `5` (mochila/paraquedas) |
| `ClothingMaleID` | number | Sim | Drawable aplicado em `mp_m_freemode_01` |
| `MaleTextureID` | number | Sim | Variação de textura para o modelo masculino |
| `ClothingFemaleID` | number | Sim | Drawable aplicado em `mp_f_freemode_01` |
| `FemaleTextureID` | number | Sim | Variação de textura para o modelo feminino |
| `InsideWeight` | number | Sim | Peso máximo do stash, em gramas |
| `Slots` | number | Sim | Número de slots do stash |
| `Item` | string | Sim | Nome do item no inventário. É esse nome que vira item usável |

Mochilas que já vêm no config:

| Item | Slots | Peso | Drawable/Textura M | Drawable/Textura F |
|---|---|---|---|---|
| `backpack1` | 15 | 100 kg | 82 / 0 | 82 / 0 |
| `backpack2` | 20 | 200 kg | 82 / 6 | 82 / 6 |
| `duffle1` | 20 | 200 kg | 82 / 4 | 82 / 0 |

> Ao adicionar uma mochila nova, inclua o nome do item também no `itemFilter` do hook `swapItems` em `server/server.lua` — a lista lá é hardcoded (`backpack1`, `backpack2`, `duffle1`) e não é derivada do `config.Bags`. Sem isso, a nova mochila pode ser guardada dentro de outra mochila.

---

## Itens no inventário

Os itens precisam existir no seu inventário com exatamente os nomes definidos em `config.Bags[i].Item`. Exemplo para `ox_inventory` (`data/items.lua`):

```lua
['backpack1'] = {
    label = 'Mochila Pequena',
    weight = 1000,
    stack = false,
    close = true,
},
['backpack2'] = {
    label = 'Mochila Grande',
    weight = 1500,
    stack = false,
    close = true,
},
['duffle1'] = {
    label = 'Bolsa Esportiva',
    weight = 800,
    stack = false,
    close = true,
},
```

Os itens **não devem ser empilháveis** (`stack = false`): o ID do stash é gravado na metadata da instância do item, e stacks fazem duas mochilas dividirem a mesma metadata.

---

## Funcionamento

### Componente visual

`client/client.lua` roda a checagem `ItemCheck` em três momentos: `QBCore:Client:OnPlayerLoaded`, `QBCore:Player:SetPlayerData` e `onResourceStart` (todos com 1s de espera). A checagem:

1. Detecta o gênero pelo modelo do ped (`mp_m_freemode_01` → `Male`, `mp_f_freemode_01` → `Female`, qualquer outro → `custom`).
2. Se o ped já estiver com o drawable/textura de alguma mochila do config, limpa o componente.
3. Se o jogador possuir algum item de mochila (`QBCore.Functions.HasItem`), aplica o drawable/textura correspondente ao gênero.

Peds com modelo customizado retornam `custom` e **não recebem o componente visual** — a função sai antes de aplicar.

### Stash da mochila

Cada item de `config.Bags` é registrado como usável no servidor. Ao usar o item:

1. Se o item ainda não tem `id` na metadata (modo `ox`) ou em `info` (modo `qb`), o servidor gera um número aleatório de 10 dígitos, checa contra `IdList.json`, grava no arquivo e grava no item.
2. No modo `ox`, o stash `Backpack<id>` é registrado com os `Slots` e `InsideWeight` da mochila e o client chama `openInventory('stash', 'Backpack<id>')`.
3. No modo `qb`, o client dispara `inventory:server:OpenInventory` com o stash `Backpack<id>`, passando `maxweight` e `slots`.

O ID acompanha a instância do item, então a mochila mantém o conteúdo ao ser trocada entre jogadores.

### Anti-dupe (somente modo `ox`)

Um hook `swapItems` do `ox_inventory` bloqueia (`return false`) qualquer movimentação dos itens `backpack1`, `backpack2` e `duffle1` para inventários que casem com `^Backpack[%w]+` — ou seja, impede guardar mochila dentro de mochila, que é o vetor clássico de dupe. Os hooks são removidos em `onServerResourceStop`.

---

## Integrações

### ox_inventory

Modo padrão (`config.InvType = "ox"`). Ativa o registro dinâmico de stash via `RegisterStash`, a gravação do ID em metadata via `SetMetadata` e o hook anti-dupe `swapItems`.

Se o seu framework for o `qb-core` original rodando com `ox_inventory`, a função `QBCore.Functions.HasItem` consulta o inventário do qb e sempre retorna falso. Aplique este patch em `qb-core/client/functions.lua` para que o componente visual da mochila funcione:

```lua
function QBCore.Functions.HasItem(items, amount)
    amount = amount or 1
    local count = exports.ox_inventory:Search('count', items)
    if type(items) == 'table' and type(count) == 'table' then
        for _, v in pairs(count) do
            if v < amount then return false end
        end
        return true
    end
    return count >= amount
end
```

O `qbx_core` já resolve `HasItem` pelo `ox_inventory` e dispensa o patch.

### qb-inventory / lj-inventory

Modo `config.InvType = "qb"`. O stash é aberto pelo evento `inventory:server:OpenInventory` com `maxweight` e `slots` passados na hora, e o ID é gravado em `item.info.id` via `SetInventory`. O hook anti-dupe **não existe** nesse modo.

---

## Entrypoints para outros recursos

### Evento `mri_Qbackpack:client:OpenBag`

Evento de rede server → client que abre o stash de uma mochila. É o único ponto de entrada exposto pelo recurso.

```lua
-- server
TriggerClientEvent('mri_Qbackpack:client:OpenBag', source, backpackId, bagIndex)
```

| Argumento | Tipo | Descrição |
|---|---|---|
| `backpackId` | number | ID de 10 dígitos da mochila (define o nome do stash: `Backpack<id>`) |
| `bagIndex` | number | Índice da mochila em `config.Bags` — usado no modo `qb` para resolver `Slots` e `InsideWeight` |

O recurso não expõe exports.

---

## Estrutura de arquivos

```
mri_Qbackpack/
├── client/
│   └── client.lua        — detecção de gênero, aplicação do componente visual, abertura do stash
├── server/
│   └── server.lua        — itens usáveis, geração de ID, RegisterStash, hook anti-dupe swapItems
├── shared/
│   └── config.lua        — framework, tipo de inventário e lista de mochilas
├── IdList.json           — IDs de mochila já emitidos (escrito em runtime; não apagar)
└── fxmanifest.lua
```
