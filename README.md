# Câmera Nativa Flutter - Captura, Reprodução e Ciclo de Vida

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

## Sobre o Projeto

Este aplicativo é uma prova de conceito (PoC) que demonstra como acessar, controlar e gerenciar os sensores físicos de um dispositivo Android de forma nativa. O objetivo principal é ilustrar as melhores práticas de comunicação direta com o hardware, gestão de arquivos multimídia e controle rigoroso de recursos de memória através da observação do ciclo de vida do sistema operacional.

## Funcionalidades Técnicas

* **Acesso Direto ao Hardware:** Inicialização da lente nativa através do `CameraController` com gerenciamento de permissões de áudio e vídeo em tempo real.
* **Captura e Reprodução de Mídia Híbrida:** * Registro de fotografias com renderização imediata do arquivo físico na interface de usuário.
  * Gravação de vídeos com reprodução em tela cheia na própria aplicação utilizando o pacote `video_player`.
* **Gerenciamento Inteligente do Ciclo de Vida:** Utilização do `WidgetsBindingObserver` para monitoramento contínuo. A câmera e os reprodutores de vídeo são desligados fisicamente (`dispose` e `pause`) quando o app entra em *background* e religados no *resume*, poupando bateria e memória RAM do dispositivo móvel.
* **Armazenamento Seguro em Cache:** Gravação de arquivos multimídia no armazenamento isolado do aplicativo, respeitando as diretrizes de segurança modernas do Android.

## Dependências do Projeto

O ecossistema do aplicativo foi mantido enxuto para evitar *bloatware*, dependendo apenas de:
* `camera: ^0.11.0` - Integração com os sensores físicos e microfone.
* `video_player: ^2.8.6` - Motor nativo de renderização de vídeo pós-captura.

## Como Executar o Projeto

### Pré-requisitos
* Flutter SDK instalado e configurado nas Variáveis de Ambiente.
* Dispositivo Android físico conectado

### grupo

* Italo
* paulo
* Josivlado
