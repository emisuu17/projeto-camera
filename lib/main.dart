import 'dart:io'; // Importação obrigatória para ler arquivos físicos do dispositivo
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart'; // Importação do pacote de vídeo

// Lista global para armazenar as câmeras físicas disponíveis no smartphone
List<CameraDescription> cameras = [];

Future<void> main() async {
  // Garante que os bindings do Flutter estão prontos antes de interagir com o hardware nativo
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Busca e lista todas as lentes disponíveis no dispositivo (frontal, traseira, etc.)
    cameras = await availableCameras();
  } catch (e) {
    print('Erro ao obter as câmeras: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demonstração de Câmera Nativa',
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData.dark(), // Tema escuro para destacar a visualização da câmera
      home: const CameraLifecycleScreen(),
    );
  }
}

class CameraLifecycleScreen extends StatefulWidget {
  const CameraLifecycleScreen({super.key});

  @override
  _CameraLifecycleScreenState createState() => _CameraLifecycleScreenState();
}

// O "with WidgetsBindingObserver" permite que a classe monitore os estados do aplicativo no sistema operacional
class _CameraLifecycleScreenState extends State<CameraLifecycleScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  VideoPlayerController?
  _videoController; // Controlador para o reprodutor de vídeo

  XFile? _arquivoCapturado;
  bool _isGravaVideo = false;
  bool _isGravando = false;

  @override
  void initState() {
    super.initState();
    // Inicia a escuta dos eventos de ciclo de vida assim que a tela é montada
    WidgetsBinding.instance.addObserver(this);

    if (cameras.isNotEmpty) {
      // Inicia com a primeira câmera da lista (geralmente a lente traseira principal)
      _inicializarCamera(cameras.first);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // Se a câmera não estiver pronta ou inicializada, interrompe a verificação
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    // Gerenciamento Inteligente do Ciclo de Vida Nativo
    if (state == AppLifecycleState.inactive) {
      // O aplicativo foi minimizado ou a tela foi bloqueada: Libera o hardware imediatamente
      cameraController.dispose();
      _videoController?.pause(); // Pausa o vídeo caso esteja em reprodução
    } else if (state == AppLifecycleState.resumed) {
      // O usuário retornou ao aplicativo: Reativa o sensor da câmera de forma transparente
      _inicializarCamera(cameraController.description);
    }
  }

  Future<void> _inicializarCamera(CameraDescription cameraDescription) async {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset
          .high, // Configuração de resolução de imagem em alta qualidade
      enableAudio:
          true, // Permissão de áudio obrigatória para o modo de gravação de vídeo
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        // Atualiza a interface gráfica para exibir o feed da câmera em tempo real
        setState(() {});
      }
    } catch (e) {
      print('Erro ao inicializar a câmera: $e');
    }
  }

  // Função para carregar e preparar o reprodutor de vídeo usando o caminho físico do arquivo salvo
  Future<void> _iniciarPlayerVideo(String path) async {
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
    await _videoController!.setLooping(
      true,
    ); // Configura o vídeo para repetição contínua (loop)
    await _videoController!
        .play(); // Inicia a reprodução automaticamente após o carregamento
  }

  Future<void> _capturarMidia() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_isGravaVideo) {
        // Fluxo de Gravação de Vídeo
        if (_isGravando) {
          // Para a gravação e salva o arquivo temporário
          final XFile video = await _controller!.stopVideoRecording();

          // Prepara e carrega o vídeo recém-gravado para exibição na tela
          await _iniciarPlayerVideo(video.path);

          setState(() {
            _isGravando = false;
            _arquivoCapturado = video;
          });
        } else {
          // Inicia a captura de vídeo
          await _controller!.startVideoRecording();
          setState(() {
            _isGravando = true;
          });
        }
      } else {
        // Fluxo de Captura de Fotografia
        final XFile foto = await _controller!.takePicture();
        setState(() {
          _arquivoCapturado = foto;
        });
      }
    } catch (e) {
      print('Erro ao capturar conteúdo de mídia: $e');
    }
  }

  @override
  void dispose() {
    // Remove o observador do ciclo de vida para evitar vazamento de memória (memory leak)
    WidgetsBinding.instance.removeObserver(this);

    // Desliga e libera os recursos de hardware da câmera
    _controller?.dispose();

    // Libera a RAM alocada pelo mecanismo de reprodução de vídeo
    _videoController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Câmera Nativa'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: _arquivoCapturado == null
                ? _construirPreviewCamera()
                : _exibirMidiaCapturada(),
          ),
          // Oculta o painel de gravação se houver uma mídia (foto/vídeo) em exibição
          if (_arquivoCapturado == null) _construirPainelControle(),
        ],
      ),
    );
  }

  Widget _construirPreviewCamera() {
    // Exibe um indicador de carregamento enquanto o hardware da câmera é ativado
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    // Mantém a proporção correta da lente para evitar que a imagem fique distorcida
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: CameraPreview(_controller!),
    );
  }

  Widget _exibirMidiaCapturada() {
    // Verifica a extensão do arquivo no caminho físico para identificar se é um vídeo (.mp4)
    bool isVideo = _arquivoCapturado!.path.toLowerCase().endsWith('.mp4');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isVideo &&
                _videoController != null &&
                _videoController!.value.isInitialized) ...[
              // Interface visual de reprodução para Vídeos com o Player embutido
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_videoController!),
                        // Botão interativo de Play/Pause sobreposto ao centro do vídeo
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _videoController!.value.isPlaying
                                  ? _videoController!.pause()
                                  : _videoController!.play();
                            });
                          },
                          child: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else if (!isVideo) ...[
              // Interface visual para Fotos (Renderiza o arquivo de imagem real)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.file(
                    File(_arquivoCapturado!.path),
                    fit: BoxFit
                        .contain, // Ajusta a imagem dentro do espaço sem cortar as bordas
                  ),
                ),
              ),
            ],

            const SizedBox(height: 15),
            Text(
              'Salvo em:\n${_arquivoCapturado!.path}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Botão de descarte para redefinir o estado e voltar para a câmera ao vivo
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                // Ao descartar a mídia, o reprodutor de vídeo é destruído para poupar memória RAM
                _videoController?.dispose();
                _videoController = null;
                setState(() => _arquivoCapturado = null);
              },
              icon: const Icon(Icons.replay),
              label: const Text('Tirar Nova Foto / Vídeo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirPainelControle() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botão seletor para alternar o estado entre o Modo Foto e o Modo Vídeo
          IconButton(
            icon: Icon(_isGravaVideo ? Icons.videocam : Icons.camera_alt),
            color: _isGravaVideo ? Colors.redAccent : Colors.blueAccent,
            iconSize: 32,
            onPressed: _isGravando
                ? null // Desabilita a troca de modo enquanto uma gravação estiver em andamento
                : () {
                    setState(() {
                      _isGravaVideo = !_isGravaVideo;
                    });
                  },
          ),
          // Botão de Disparo Principal (Obturador)
          GestureDetector(
            onTap: _capturarMidia,
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                // Altera a cor da borda para vermelho para sinalizar gravação ativa
                color: _isGravando ? Colors.red : Colors.transparent,
              ),
              child: Center(
                child: Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Torna o centro transparente durante a gravação para o efeito visual clássico de vídeo
                    color: _isGravando ? Colors.transparent : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // Espaçador invisível para manter o equilíbrio visual e a centralização do botão de disparo
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
