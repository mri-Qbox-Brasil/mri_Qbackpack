# mri_Qbackpack - Manual Funcional

Sistema de mochilas/bags para FiveM com equipamento visual no ped e inventário stash dedicado. Compatível com QB-inventory, LJ-inventory e ox_inventory.

## O que o recurso faz

O mri_Qbackpack gerencia mochilas no jogo, aplicando automaticamente o componente visual (prop) no ped do jogador quando ele possui o item no inventário, e criando um inventário stash dedicado e persistente para cada mochila, permitindo armazenar itens dentro da mochila equipada.

## Funcionalidades principais

- **Equipamento visual automático**: Aplica componente de mochila no ped do jogador quando ele possui o item no inventário
- **Detecção de gênero**: Aplica variações corretas de clothing para peds masculinos e femininos
- **Stash persistente por mochila**: Cada mochila ganha um inventário único com ID próprio, slots e peso configuráveis
- **Suporte dual-inventory**: Funciona com QB-inventory/LJ-inventory (`"qb"`) e ox_inventory (`"ox"`)
- **Prevenção de dupes**: Hook `swapItems` no ox_inventory impede mover itens de mochila para dentro da própria mochila
- **IDs únicos persistentes**: Cada mochila recebe um ID de 10 dígitos gerado automaticamente, persistido em `IdList.json`

## Como funciona

### Fluxo de equipamento visual
1. Ao carregar o jogador (`OnPlayerLoaded`), o cliente verifica se ele possui algum item de mochila no inventário
2. Se possuir, o componente de mochila (slot 5) é aplicado ao ped com as variações corretas de gênero
3. Se trocar de mochila, a anterior é removida automaticamente antes de aplicar a nova
4. O check é re-executado em `OnPlayerLoaded`, `SetPlayerData` e `onResourceStart`

### Fluxo de uso da mochila
1. O jogador usa o item de mochila no inventário (`UseableItem`)
2. **Primeiro uso**: um ID único é gerado e atribuído ao item
3. Um stash com nome `Backpack<id>` é criado/aberto com os slots e peso configurados
4. Usos subsequentes reabrem o mesmo stash pelo ID persistente

### Prevenção de dupes (ox_inventory)
Um hook `swapItems` é registrado para impedir que itens de mochila (`backpack1`, `backpack2`, `duffle1`) sejam movidos para dentro de qualquer stash que corresponda ao padrão `^Backpack[%w]+`.

## Configurações disponíveis (shared/config.lua)

### Configurações gerais
| Opção | Padrão | Descrição |
|-------|---------|-----------|
| `config.FrameworkResource` | `"qb-core"` | Nome do resource do framework (QBCore) |
| `config.InvType` | `"ox"` | Tipo de inventory: `"qb"` ou `"ox"` |
| `config.InvName` | `"ox_inventory"` | Nome do resource de inventory instalado |

### Definição de mochilas (config.Bags)
Cada mochila é definida com:

| Campo | Exemplo | Descrição |
|-------|---------|-----------|
| `ComponentId` | `5` | Slot do componente GTA (5 = mochila/paraquedas) |
| `ClothingMaleID` | `82` | Drawable ID para peds masculinos |
| `MaleTextureID` | `0` | Texture variant para masculinos |
| `ClothingFemaleID` | `82` | Drawable ID para peds femininos |
| `FemaleTextureID` | `0` | Texture variant para femininos |
| `InsideWeight` | `100000` | Peso máximo da mochila em gramas |
| `Slots` | `15` | Número de slots no inventário da mochila |
| `Item` | `"backpack1"` | Nome do item no inventory |

### Mochilas pré-configuradas
| Item | Slots | Peso | Drawable M | Texture M | Drawable F | Texture F |
|------|-------|------|------------|-----------|------------|-----------|
| `backpack1` | 15 | 100kg | 82 | 0 | 82 | 0 |
| `backpack2` | 20 | 200kg | 82 | 6 | 82 | 6 |
| `duffle1` | 20 | 200kg | 82 | 4 | 0 | 0 |

## Eventos

### Server → Client
| Evento | Payload | Descrição |
|--------|---------|-----------|
| `mri_Qbackpack:client:OpenBag` | `(ItemID, ItemInfo)` | Abre o inventário stash da mochila |

### Client (ouvidos)
| Evento | Origem | Descrição |
|--------|--------|-----------|
| `QBCore:Client:OnPlayerLoaded` | qb-core/qbx_core | Dispara verificação visual da mochila no login |
| `QBCore:Player:SetPlayerData` | qb-core/qbx_core | Dispara verificação visual ao alterar dados |

## Itens necessários (inventory)

Defina os seguintes itens no seu inventory:

```lua
['backpack1'] = {
    label = 'Mochila Pequena',
    weight = 1000,
    type = 'item',
    image = 'backpack1.png',
    description = 'Uma mochila pequena com 15 slots',
},
['backpack2'] = {
    label = 'Mochila Grande',
    weight = 1500,
    type = 'item',
    image = 'backpack2.png',
    description = 'Uma mochila grande com 20 slots',
},
['duffle1'] = {
    label = 'Bolsa Esportiva',
    weight = 800,
    type = 'item',
    image = 'duffle1.png',
    description = 'Uma bolsa esportiva com 20 slots',
},
```

## Integração com outros recursos MRI

### Obrigatórias
- `qb-core` ou `qbx_core` — Framework principal
- `qb-inventory` / `lj-inventory` / `ox_inventory` — Sistema de inventário

### Compatibilidade com ox_inventory
Para tornar `QBCore.Functions.HasItem` compatível com ox_inventory, aplique este patch em `qb-core/client/functions.lua`:

```lua
function QBCore.Functions.HasItem(items, amount)
    amount = amount or 1
    local count = exports.ox_inventory:Search('count', items)
    if type(items) == 'table' and type(count) == 'table' then
        for _, v in pairs(count) do
            if v < amount then
                return false
            end
        end
        return true
    end
    return count >= amount
end
```

## Exemplos práticos

### Adicionar nova mochila
```lua
-- shared/config.lua
config.Bags = {
    -- mochilas existentes...
    {
        ComponentId = 5,
        ClothingMaleID = 84,
        MaleTextureID = 0,
        ClothingFemaleID = 84,
        FemaleTextureID = 0,
        InsideWeight = 150000,
        Slots = 25,
        Item = "backpack3",
    },
}
```

### Verificar se jogador tem mochila equipada
```lua
if QBCore.Functions.HasItem('backpack1') then
    -- jogador tem mochila pequena
end
```

### Abrir stash manualmente (server)
```lua
TriggerClientEvent('mri_Qbackpack:client:OpenBag', source, ItemID, ItemInfo)
```

## Solução de problemas

- **Mochila visual não aparece**: Verifique se o item está no inventário e se o ped é `mp_m_freemode_01` ou `mp_f_freemode_01`
- **Gênero não detecta**: Detecção funciona apenas com modelos padrão; peds customizados retornam `"custom"` e não recebem mochila
- **Stash não abre**: Confirme que o ID foi gerado e salvo em `IdList.json`
- **Dupes de itens**: Hook `swapItems` no ox_inventory impede movimento para dentro da própria mochila
- **IDs perdidos**: Não delete o arquivo `IdList.json` — ele persiste os IDs entre restarts
- **Itens hardcodados no hook**: No modo `ox`, o hook usa nomes hardcodados; idealmente deveria derivar do config
- **Inventário não sincroniza**: Verifique se `config.InvType` e `config.InvName` estão corretos
