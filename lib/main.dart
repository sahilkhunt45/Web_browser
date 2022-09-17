import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebBrowser(),
    ),
  );
}

class WebBrowser extends StatefulWidget {
  const WebBrowser({Key? key}) : super(key: key);

  @override
  State<WebBrowser> createState() => _WebBrowserState();
}

class _WebBrowserState extends State<WebBrowser> {
  final GlobalKey inAppWebViewKey = GlobalKey();
  InAppWebViewController? inAppWebViewController;
  late PullToRefreshController pullToRefreshController;
  final TextEditingController searchController = TextEditingController();
  String searchText = "";
  List<String> allBookmark = [];

  double progress = 0;
  String url = "";
  final urlController = TextEditingController();

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: true,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsAirPlayForMediaPlayback: true,
    ),
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pullToRefreshController = PullToRefreshController(
        options: PullToRefreshOptions(),
        onRefresh: () async {
          if (Platform.isAndroid) {
            inAppWebViewController?.reload();
          } else if (Platform.isIOS) {
            inAppWebViewController?.loadUrl(
              urlRequest: URLRequest(
                url: await inAppWebViewController?.getUrl(),
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Web Browser"),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              Uri? uri = await inAppWebViewController!.getUrl();
              allBookmark.add(uri!.toString());

              allBookmark = allBookmark.toSet().toList();
            },
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: (context),
                builder: (context) => AlertDialog(
                    title: const Center(
                      child: Text("All Bookmarks"),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        children: allBookmark
                            .map(
                              (e) => TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  inAppWebViewController!.loadUrl(
                                    urlRequest: URLRequest(
                                      url: Uri.parse(e),
                                    ),
                                  );
                                },
                                child: Text(e),
                              ),
                            )
                            .toList(),
                      ),
                    )),
              );
            },
            icon: const Icon(Icons.bookmarks),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: TextField(
                controller: searchController,
                onSubmitted: (val) async {
                  searchText = val;
                  Uri uri = Uri.parse(searchText);

                  if (uri.scheme.isEmpty) {
                    uri = Uri.parse(
                        "https://www.google.com/search?q=" + searchText);
                  }

                  await inAppWebViewController!.loadUrl(
                    urlRequest: URLRequest(url: uri),
                  );
                },
                decoration: const InputDecoration(
                  hintText: "Search Your Website....",
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          progress < 1.0
              ? LinearProgressIndicator(value: progress)
              : Container(),
          Expanded(
            flex: 15,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                InAppWebView(
                  pullToRefreshController: pullToRefreshController,
                  initialOptions: options,
                  key: inAppWebViewKey,
                  initialUrlRequest: URLRequest(
                    url: Uri.parse("https://www.google.co.in"),
                  ),
                  onWebViewCreated: (controller) {
                    inAppWebViewController = controller;
                  },
                  onLoadStop: (controller, url) async {
                    searchController.text = url.toString();
                    await pullToRefreshController.endRefreshing();
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      pullToRefreshController.endRefreshing();
                    }
                    setState(() {
                      this.progress = progress / 100;
                      searchController.text = this.url;
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    setState(() {
                      this.url = url.toString();
                      searchController.text = this.url;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    print(consoleMessage);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        onPressed: () async {
                          if (await inAppWebViewController!.canGoBack()) {
                            await inAppWebViewController!.goBack();
                          }
                        },
                        child: const Icon(Icons.arrow_back_ios_outlined),
                      ),
                      FloatingActionButton(
                        onPressed: () async {
                          await inAppWebViewController!.loadUrl(
                            urlRequest: URLRequest(
                              url: Uri.parse("https://www.google.co.in"),
                            ),
                          );
                        },
                        child: const Icon(Icons.home_filled),
                      ),
                      FloatingActionButton(
                        onPressed: () async {
                          await inAppWebViewController!.reload();
                        },
                        child: const Icon(Icons.refresh),
                      ),
                      FloatingActionButton(
                        onPressed: () async {
                          if (await inAppWebViewController!.canGoForward()) {
                            await inAppWebViewController!.goForward();
                          }
                        },
                        child: const Icon(Icons.arrow_forward_ios_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
