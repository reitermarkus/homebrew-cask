cask 'react-native-debugger' do
  version '0.9.6'
  sha256 'bc5459066e7dad54012ed080c6f2b59d4e8df75092effbbb262880df4cd04d97'

  url "https://github.com/jhen0409/react-native-debugger/releases/download/v#{version}/rn-debugger-macos-x64.zip"
  appcast 'https://github.com/jhen0409/react-native-debugger/releases.atom'
  name 'React Native Debugger'
  homepage 'https://github.com/jhen0409/react-native-debugger'

  app 'React Native Debugger.app'
end
