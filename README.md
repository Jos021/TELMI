# Telmi — Roblox Game (MVP)

Jogo de sobrevivência, construção, clãs e guerra em blocos no Roblox.

## Estrutura do Projeto

```
src/
├── Shared/                  → ReplicatedStorage/Shared (acessível por servidor e cliente)
│   ├── Config.lua           → Todas as constantes do jogo
│   ├── Remotes.lua          → Criação dos RemoteEvents e RemoteFunctions
│   └── Utils.lua            → Funções utilitárias
├── Server/                  → ServerScriptService/Server
│   ├── Main.server.lua      → Entrada do servidor
│   └── Systems/
│       ├── DataSystem.lua         → DataStore (salvar/carregar)
│       ├── InventorySystem.lua    → Inventário de recursos
│       ├── ResourceSystem.lua     → Nós de recursos no mapa
│       ├── ConstructionSystem.lua → Colocação de construções
│       ├── BaseSystem.lua         → Base persistente e Centro do Clã
│       ├── ClanSystem.lua         → Sistema de clãs
│       ├── CombatSystem.lua       → Combate (espada, arco, armadura)
│       ├── RaidSystem.lua         → Sistema de raids
│       └── ProtectionSystem.lua   → Proteção de novatos
└── Client/                  → StarterPlayer/StarterPlayerScripts/Client
    ├── Main.client.lua      → Entrada do cliente
    └── Controllers/
        ├── HUDController.lua        → HUD (vida, recursos, notificações)
        ├── InventoryController.lua  → UI de inventário
        ├── BuildingController.lua   → Preview e colocação de construções
        └── ClanController.lua       → UI do clã
```

## Como usar com Rojo

1. Instale o Rojo: https://rojo.space
2. Execute `rojo serve` na pasta do projeto
3. No Roblox Studio, conecte via plugin do Rojo

## Controles

| Tecla | Ação |
|-------|------|
| `I` | Abrir/fechar inventário |
| `B` | Abrir menu de construção |
| `G` | Abrir painel do clã |
| `E` | Remover construção (aponte com o mouse) |
| Clique esquerdo | Colocar construção (no modo build) |
| Clique direito / Esc | Cancelar modo de construção |

## MVP — Sistemas implementados

- **Recursos**: Madeira, Pedra, Ferro e Comida (coletáveis no mapa)
- **Inventário**: Persistente com DataStore
- **Construção**: 8 tipos de blocos com preview em grid
- **Base Persistente**: Salva e carrega construções ao entrar/sair
- **Centro do Clã**: Nível 1–6, capacidade de 3 a 50 membros
- **Sistema de Clã**: Criar, convidar, aceitar, expulsar, sair
- **Combate**: Espada e Arco com cooldown e validação server-side
- **Raid**: Declarar raid, timer, saque parcial (30%), sem wipe total
- **Proteção de Novatos**: 30 minutos iniciais sem poder ser atacado
- **HUD**: Barra de vida, recursos, notificações, info do clã

## Fora do MVP (roadmap)

- Modo Survival 10 Minutos
- Guerras 10v10, 20v20, 30v30, 50v50
- Territórios e biomas avançados
- Matchmaking sofisticado
- Monetização (skins, cosméticos)
- Ranking competitivo
