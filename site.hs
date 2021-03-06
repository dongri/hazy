--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll


--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let newPosts = reverse posts
            let archiveCtx =
                    listField "posts" postCtx (return newPosts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let newPosts = reverse posts
            let indexCtx =
                    listField "posts" postCtx (return newPosts) `mappend`
                    constField "title" "Home"                `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext


--------------------------------------------------------------------------------
config :: Configuration
config = defaultConfiguration
    { deployCommand = "git checkout master" `mappend`
                      "&& stack exec site rebuild" `mappend`
                      "&& git add -A" `mappend`
                      "&& git commit -m 'Edit'" `mappend`
                      "&& git push -f origin master" `mappend`
                      "&& git branch -D gh-pages" `mappend`
                      "&& git checkout -b gh-pages" `mappend`
                      "&& rsync -a --filter='P _site/'" `mappend`
                      " --filter='P _cache/' --filter='P .git/'" `mappend`
                      " --filter='P .stack-work' --filter='P .gitignore'" `mappend`
                      " --delete-excluded _site/ ." `mappend`
                      "&& cp -a _site/. ." `mappend`
                      "&& git add -A" `mappend`
                      "&& git commit -m 'Publish'" `mappend`
                      "&& git push -f origin gh-pages" `mappend`
                      "&& git checkout master"
    }
