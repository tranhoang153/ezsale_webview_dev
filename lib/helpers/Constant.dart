const appName = "Ezsy\$ALES";

const bool testEnviroment = false;

String webinitialUrl = testEnviroment
    ? 'https://ezsale-next.vercel.app/'
    : 'https://ezsale-next.vercel.app/';
const String firstTabUrl = testEnviroment
    ? 'https://ezsale-next.vercel.app/'
    : 'https://ezsale-next.vercel.app/';

const List<String> listBottomUrl = testEnviroment
    ? [
        'https://qa-www.wwwow.ai/Project/b2g',
        'https://qa-www.wwwow.ai/Operation/list',
        'https://qa-www.wwwow.ai/Partner/recommend',
        'https://qa-www.wwwow.ai/dashboard',
        'https://qa-www.wwwow.ai/Mypage'
      ]
    : [
        'https://wwwow.ai/Project/b2g',
        'https://wwwow.ai/Operation/list',
        'https://wwwow.ai/dashboard',
        'https://wwwow.ai/Partner/recommend',
        'https://wwwow.ai/Mypage'
      ];

const bool hideHeader = false;
const bool hideFooter = false;

const String iconPath = 'assets/icons/';

const bool isStoragePermissionEnabled = false;

String baseURL =
    testEnviroment ? 'https://qa-www.wwwow.ai/Apis/' : 'https://wwwow.ai/Apis/';
